"""Core triage logic for the ticket triage CLI."""

import json
from collections import namedtuple
from pathlib import Path
from typing import Optional
import os

import yaml

# Try to import requests for LLM mode - optional dependency
try:
    import requests

    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

TriageResult = namedtuple(
    "TriageResult",
    [
        "category",
        "priority",
        "action",
        "escalate_to",
        "kb",
        "signals",
        "confidence",
        "flag_l2",
    ],
)

# Priority level mappings
PRIORITY_LEVELS = {"P1": 1, "P2": 2, "P3": 3, "P4": 4}
PRIORITY_LABELS = {1: "P1 (Critical)", 2: "P2 (Medium)", 3: "P3 (Low)", 4: "P4 (Info)"}


def get_config_path() -> Path:
    """Get the user config path for Windows (%APPDATA%\ticket-triage\rules.yaml)."""
    appdata = os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming")
    return Path(appdata) / "ticket-triage" / "rules.yaml"


def load_rules() -> dict:
    """Load rules from package defaults and merge with user config if present."""
    # Load default rules from package directory
    default_rules_path = Path(__file__).parent / "rules.yaml"

    with open(default_rules_path, "r", encoding="utf-8") as f:
        rules = yaml.safe_load(f)

    # Merge with user config if it exists
    user_config = get_config_path()
    if user_config.exists():
        try:
            with open(user_config, "r", encoding="utf-8") as f:
                user_rules = yaml.safe_load(f)
            if user_rules and "categories" in user_rules:
                rules["categories"].update(user_rules["categories"])
            if user_rules and "priority" in user_rules:
                rules["priority"].update(user_rules["priority"])
            if user_rules and "escalation" in user_rules:
                rules["escalation"].update(user_rules["escalation"])
        except Exception:
            # If user config is invalid, use defaults silently
            pass

    return rules


def score_confidence(matched_keywords: list, category_count: int) -> str:
    """Score confidence based on keyword match count and category overlap.

    - High: exactly one category matched, 3+ keywords hit
    - Medium: exactly one category matched, 1-2 keywords hit
    - Low: multiple categories matched or no category matched
    """
    if category_count > 1:
        return "Low"
    if len(matched_keywords) >= 3:
        return "High"
    if len(matched_keywords) >= 1:
        return "Medium"
    return "Low"


def score_priority(ticket_text: str, category: str, rules: dict) -> tuple[str, bool]:
    """Score priority based on ticket text and category rules.

    Returns (priority_label, was_bumped_by_urgency).

    Priority logic:
    1. Start with P2 as default
    2. Check for P1 override words (critical issues)
    3. Check for P3 indicators (low priority)
    4. Check for P4 indicators (informational)
    5. Apply urgency modifier bump (one level up)
    6. Apply category-specific priority bump
    """
    priority_config = rules.get("priority", {})

    # Start with base priority P2
    base_priority = "P2"

    # Check for P1 override words
    p1_words = priority_config.get("p1_override_words", [])
    ticket_lower = ticket_text.lower()

    for word in p1_words:
        if word.lower() in ticket_lower:
            base_priority = "P1"
            break

    # If no P1, check for P3 indicators
    if base_priority == "P2":
        p3_words = priority_config.get("p3_indicator_words", [])
        for word in p3_words:
            if word.lower() in ticket_lower:
                base_priority = "P3"
                break

    # Check for P4 indicators (overrides P3)
    p4_words = priority_config.get("p4_indicator_words", [])
    for word in p4_words:
        if word.lower() in ticket_lower:
            base_priority = "P4"
            break

    # Check for urgency modifiers (bump priority up one level)
    urgency_words = priority_config.get("urgency_modifiers", [])
    urgency_bump = False
    for word in urgency_words:
        if word.lower() in ticket_lower:
            urgency_bump = True
            break

    # Get category priority bump
    categories = rules.get("categories", {})
    category_data = categories.get(category, {})
    priority_bump = category_data.get("priority_bump", 0)

    # Calculate final priority level
    level = PRIORITY_LEVELS[base_priority]

    # Apply urgency bump (one level up, P1 stays P1)
    if urgency_bump and level > 1:
        level -= 1

    # Apply category-specific bump
    level = max(1, level - priority_bump)

    return PRIORITY_LABELS[level], urgency_bump


def check_escalation(
    ticket_text: str,
    category: str,
    priority: str,
    rules: dict,
    matched_categories: list,
) -> tuple[bool, str]:
    """Check if ticket should be escalated to L2.

    Returns (should_escalate, escalation_message).

    Escalation rules:
    1. Hardware + failure keywords → L2 immediate
    2. Multiple categories detected → L2 review
    3. P1 + Authentication → L2 + Security
    4. MFA issues with Authentication → L2
    5. Security keywords detected → L2 + Security
    """
    escalation_config = rules.get("escalation", {})
    categories = rules.get("categories", {})
    ticket_lower = ticket_text.lower()

    flag_l2 = False
    reasons = []

    # Rule: Hardware failure keywords
    if category == "hardware":
        hw_failure_words = escalation_config.get("hardware_failure_keywords", [])
        for word in hw_failure_words:
            if word.lower() in ticket_lower:
                flag_l2 = True
                reasons.append("Hardware failure detected")
                break

    # Rule: Multiple categories detected
    if len(matched_categories) > 1:
        flag_l2 = True
        reasons.append("Multiple categories detected - needs review")

    # Rule: P1 + Authentication
    if priority.startswith("P1") and category == "authentication":
        flag_l2 = True
        reasons.append("P1 Authentication issue - Security team involvement")

    # Rule: MFA issues with Authentication
    if category == "authentication":
        mfa_words = escalation_config.get("mfa_keywords", [])
        for word in mfa_words:
            if word.lower() in ticket_lower:
                flag_l2 = True
                reasons.append("MFA issue detected")
                break

    # Rule: Security keywords
    security_words = escalation_config.get("security_keywords", [])
    for word in security_words:
        if word.lower() in ticket_lower:
            flag_l2 = True
            reasons.append("Security-related keywords detected")
            break

    # Get escalation message from category config
    category_data = categories.get(category, {})
    base_escalation = category_data.get("escalation", "None")

    if flag_l2:
        if reasons:
            escalation_msg = f"L2 - {'; '.join(reasons)}"
        else:
            escalation_msg = (
                base_escalation
                if base_escalation != "None"
                else "L2 review recommended"
            )
    else:
        escalation_msg = base_escalation

    return flag_l2, escalation_msg


def ollama_triage(ticket_text: str, rules: dict) -> Optional[TriageResult]:
    """Use local Ollama for enhanced triage.

    Returns refined TriageResult or None if Ollama unavailable.
    Falls back to rule engine if Ollama is down.
    """
    if not HAS_REQUESTS:
        return None

    categories = rules.get("categories", {})
    category_names = [k.replace("_", " ").title() for k in categories.keys()]

    prompt = f"""Analyze this support ticket and provide a structured triage:

Ticket: {ticket_text}

Available categories: {", ".join(category_names)}

Return a JSON object with these exact fields:
- category: best matching category from the list
- priority: P1, P2, P3, or P4
- confidence: High, Medium, or Low
- reasoning: brief explanation of your classification

Response format (JSON only):"""

    try:
        resp = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "llama3.2",
                "prompt": prompt,
                "stream": False,
                "format": "json",
            },
            timeout=5,
        )

        if resp.status_code != 200:
            return None

        llm_response = resp.json()
        llm_result = json.loads(llm_response.get("response", "{}"))

        # Map LLM result to TriageResult
        llm_category = llm_result.get("category", "Other/Unknown")
        # Find matching internal category name
        internal_cat = None
        for cat_key, cat_data in categories.items():
            display_name = cat_key.replace("_", " ").title()
            if llm_category.lower() in [display_name.lower(), cat_key.lower()]:
                internal_cat = cat_key
                break

        if not internal_cat:
            return None

        cat_data = categories.get(internal_cat, {})

        # Determine if L2 escalation needed based on LLM confidence and category
        priority = llm_result.get("priority", "P2")
        priority_label = PRIORITY_LABELS.get(
            PRIORITY_LEVELS.get(priority, 2), "P2 (Medium)"
        )

        flag_l2, escalate_to = check_escalation(
            ticket_text, internal_cat, priority_label, rules, [internal_cat]
        )

        return TriageResult(
            category=llm_category,
            priority=priority_label,
            action=cat_data.get("suggested_action", "No action available"),
            escalate_to=escalate_to,
            kb=cat_data.get("kb", "KB-0000"),
            signals=[],
            confidence=llm_result.get("confidence", "Medium"),
            flag_l2=flag_l2,
        )

    except Exception:
        # Any error falls back to rule engine
        return None


def triage(
    raw_ticket: str, rules: Optional[dict] = None, use_llm: bool = False
) -> TriageResult:
    """Main triage function.

    1. If use_llm=True and Ollama available, try LLM refinement
    2. Otherwise, use rule engine triage
    3. Return TriageResult
    """
    if not raw_ticket or not raw_ticket.strip():
        raise ValueError("empty ticket")

    if rules is None:
        rules = load_rules()

    # Try LLM mode if requested
    if use_llm:
        llm_result = ollama_triage(raw_ticket, rules)
        if llm_result is not None:
            return llm_result
        # Fall back to rule engine silently

    # Rule engine triage
    # Normalize input
    ticket_lower = raw_ticket.lower()

    # Get all categories
    categories = rules.get("categories", {})

    # Track matches per category
    category_matches = {}
    all_matched_keywords = []

    for cat_name, cat_data in categories.items():
        if cat_name == "other_unknown":
            continue

        keywords = cat_data.get("keywords", [])
        matched = []

        for keyword in keywords:
            # Simple word boundary check
            if keyword.lower() in ticket_lower:
                matched.append(keyword)
                if keyword not in all_matched_keywords:
                    all_matched_keywords.append(keyword)

        if matched:
            category_matches[cat_name] = {"keywords": matched, "count": len(matched)}

    # Determine primary category (highest keyword count)
    if category_matches:
        # Sort by match count, then by category name for consistency
        sorted_cats = sorted(
            category_matches.items(), key=lambda x: (-x[1]["count"], x[0])
        )
        primary_category = sorted_cats[0][0]
        matched_categories = list(category_matches.keys())
    else:
        primary_category = "other_unknown"
        matched_categories = []

    # Score priority
    priority, _ = score_priority(raw_ticket, primary_category, rules)

    # Score confidence
    primary_keywords = category_matches.get(primary_category, {}).get("keywords", [])
    confidence = score_confidence(primary_keywords, len(matched_categories))

    # Check escalation
    flag_l2, escalate_to = check_escalation(
        raw_ticket, primary_category, priority, rules, matched_categories
    )

    # Get category data for output
    cat_data = categories.get(primary_category, {})
    action = cat_data.get("suggested_action", "No action available")
    kb = cat_data.get("kb", "KB-0000")

    # Format category name: map internal names to display names
    category_display_map = {
        "network_vpn": "Network/VPN",
        "email_outlook": "Email/Outlook",
        "access_request": "Access Request",
        "other_unknown": "Other/Unknown",
        "authentication": "Authentication",
        "hardware": "Hardware",
        "software": "Software",
        "printing": "Printing",
    }
    category_display = category_display_map.get(
        primary_category, primary_category.replace("_", " ").title()
    )

    return TriageResult(
        category=category_display,
        priority=priority,
        action=action,
        escalate_to=escalate_to,
        kb=kb,
        signals=primary_keywords[:5],  # Top 5 signals
        confidence=confidence,
        flag_l2=flag_l2,
    )
