"""Core triage logic for ticket-triage CLI."""

import json
import re
from collections import namedtuple
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

import yaml

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

# Priority levels mapping
PRIORITY_LEVELS = {"P1": 1, "P2": 2, "P3": 3, "P4": 4}
PRIORITY_LABELS = {1: "P1 (Critical)", 2: "P2 (Medium)", 3: "P3 (Low)", 4: "P4 (Info)"}

# P1 override keywords
P1_OVERRIDE_WORDS = ["down", "outage", "everyone", "production", "urgent"]

# P3 indicator keywords
P3_INDICATORS = ["when possible", "cosmetic", "minor issue", "question"]

# P4 indicator keywords
P4_INDICATORS = ["fyi", "for reference", "no action needed", "info only"]

# Urgency modifiers
URGENCY_MODIFIERS = ["asap", "immediately", "right now", "urgent"]


def load_rules() -> Dict[str, Any]:
    """Load default rules and merge with user config if exists."""
    # Load default rules
    default_rules_path = Path(__file__).parent / "rules.yaml"
    with open(default_rules_path, "r") as f:
        rules = yaml.safe_load(f)

    # Check for user config
    user_rules_path = Path.home() / ".config" / "ticket-triage" / "rules.yaml"
    if user_rules_path.exists():
        with open(user_rules_path, "r") as f:
            user_rules = yaml.safe_load(f)
        if user_rules and "categories" in user_rules:
            rules["categories"].update(user_rules["categories"])

    return rules


def score_priority(
    ticket_text: str, matched_category: str, rules: Dict[str, Any]
) -> Tuple[str, bool]:
    """
    Score priority based on keywords and modifiers.
    Returns (priority_label, has_urgency_modifier).
    """
    text_lower = ticket_text.lower()

    # Check for P1 override words
    has_p1_override = any(word in text_lower for word in P1_OVERRIDE_WORDS)

    # Check for urgency modifiers
    has_urgency = any(mod in text_lower for mod in URGENCY_MODIFIERS)

    # Determine base priority
    if has_p1_override:
        base_level = 1
    elif any(ind in text_lower for ind in P4_INDICATORS):
        base_level = 4
    elif any(ind in text_lower for ind in P3_INDICATORS):
        base_level = 3
    else:
        base_level = 2  # Default P2

    # Apply urgency bump (decrease level number = increase priority)
    if has_urgency and base_level > 1:
        base_level -= 1

    # Apply category priority bump
    category_data = rules.get("categories", {}).get(matched_category.lower(), {})
    priority_bump = category_data.get("priority_bump", 0)
    base_level = max(1, base_level - priority_bump)

    return PRIORITY_LABELS[base_level], has_urgency


def score_confidence(matched_keywords: List[str], category_count: int) -> str:
    """
    Score confidence based on keyword matches and category overlap.
    """
    if category_count > 1:
        return "Low"
    if len(matched_keywords) >= 3:
        return "High"
    if len(matched_keywords) >= 1:
        return "Medium"
    return "Low"


def check_escalation(
    ticket_text: str, category: str, priority: str, matched_keywords: List[str]
) -> Tuple[bool, str]:
    """
    Check if ticket should be escalated to L2.
    Returns (flag_l2, escalation_message).
    """
    text_lower = ticket_text.lower()

    # Hardware + failure keywords → L2 immediate
    if category.lower() == "hardware":
        failure_words = ["failure", "failed", "broken", "dead"]
        if any(word in text_lower for word in failure_words):
            return True, "L2 immediate - hardware failure"

    # P1 + Authentication → L2 + Security
    if category.lower() == "authentication" and priority.startswith("P1"):
        return True, "L2 + Security - P1 authentication issue"

    # MFA or locked account in authentication (only if not already flagged for P1)
    if category.lower() == "authentication":
        if "mfa" in text_lower or "locked" in text_lower:
            return True, "L2 if MFA not working or account locked"

    return False, "None"


def triage(
    raw_ticket: str, rules: Dict[str, Any], use_llm: bool = False
) -> TriageResult:
    """
    Main triage function.

    1. Lowercase + strip input
    2. Extract keywords (simple word boundary match)
    3. Match against category keywords
    4. Score priority (P1 override words + base score)
    5. Score confidence based on match count and category overlap
    6. Check escalation conditions
    7. Return TriageResult
    """
    text_lower = raw_ticket.lower().strip()

    if not text_lower:
        raise ValueError("Empty ticket text provided")

    # Match categories
    categories = rules.get("categories", {})
    category_scores = {}
    matched_keywords_per_category = {}

    for cat_name, cat_data in categories.items():
        keywords = cat_data.get("keywords", [])
        matched = []
        for kw in keywords:
            kw_lower = kw.lower()
            # For multi-word keywords (contain space), use simple substring match
            # For single-word keywords, use word boundary matching
            if " " in kw_lower:
                # Multi-word: simple substring match
                if kw_lower in text_lower:
                    matched.append(kw)
            else:
                # Single-word: use word boundary to avoid partial matches
                # e.g., "app" should not match "happened"
                pattern = r"\b" + re.escape(kw_lower) + r"\b"
                if re.search(pattern, text_lower):
                    matched.append(kw)
        if matched:
            category_scores[cat_name] = len(matched)
            matched_keywords_per_category[cat_name] = matched

    # Determine best category
    if not category_scores:
        best_category = "Other/Unknown"
        all_signals = []
    else:
        best_category = max(category_scores, key=category_scores.get)
        all_signals = matched_keywords_per_category[best_category]

    # Score priority
    priority, _ = score_priority(raw_ticket, best_category, rules)

    # Score confidence
    category_count = len(category_scores)
    confidence = score_confidence(all_signals, category_count)

    # Check escalation
    flag_l2, escalate_to = check_escalation(
        raw_ticket, best_category, priority, all_signals
    )

    # Get action and KB from rules
    cat_data = categories.get(best_category.lower(), {})
    action = cat_data.get("suggested_action", "Review ticket manually")
    kb = cat_data.get("kb", "N/A")

    return TriageResult(
        category=best_category,
        priority=priority,
        action=action,
        escalate_to=escalate_to,
        kb=kb,
        signals=all_signals,
        confidence=confidence,
        flag_l2=flag_l2,
    )


def format_result(result: TriageResult) -> str:
    """Format triage result as text output."""
    lines = [
        f"Category: {result.category}",
        f"Priority: {result.priority}",
        f"Suggested action: {result.action}",
        f"Escalate to: {result.escalate_to}",
        f"Related KB: {result.kb}",
        f"Root cause signals: {result.signals}",
        f"Confidence: {result.confidence}",
    ]
    return "\n".join(lines)


def format_json(result: TriageResult) -> str:
    """Format triage result as JSON output."""
    data = {
        "category": result.category,
        "priority": result.priority.split()[0] if result.priority else "P2",
        "action": result.action,
        "escalate_to": result.escalate_to,
        "kb": result.kb,
        "signals": result.signals,
        "confidence": result.confidence,
        "flag_l2": result.flag_l2,
    }
    return json.dumps(data, indent=2)
