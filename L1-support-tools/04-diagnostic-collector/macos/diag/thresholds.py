"""
Threshold detection for diagnostic data
"""

from typing import Dict, List, Tuple


class ThresholdChecker:
    """Check diagnostic data against thresholds and generate warnings."""

    # Thresholds
    DISK_WARNING = 80
    DISK_CRITICAL = 90
    MEMORY_WARNING = 80
    MEMORY_CRITICAL = 90

    def __init__(self):
        self.warnings: List[str] = []
        self.criticals: List[str] = []
        self.infos: List[str] = []

    def check_disk(self, percent_used: int, mount: str = "/") -> str:
        """
        Check disk usage percentage against thresholds.
        Returns: 'OK', 'WARNING HIGH', or 'CRITICAL'
        """
        if percent_used >= self.DISK_CRITICAL:
            self.criticals.append(
                f"Disk {mount}: {percent_used}% used (CRITICAL threshold: {self.DISK_CRITICAL}%)"
            )
            return "CRITICAL"
        elif percent_used >= self.DISK_WARNING:
            self.warnings.append(
                f"Disk {mount}: {percent_used}% used (WARNING threshold: {self.DISK_WARNING}%)"
            )
            return "WARNING HIGH"
        return "OK"

    def check_memory(self, percent_used: int) -> str:
        """
        Check memory usage percentage against thresholds.
        Returns: 'OK', 'WARNING HIGH', or 'CRITICAL'
        """
        if percent_used >= self.MEMORY_CRITICAL:
            self.criticals.append(
                f"Memory: {percent_used}% used (CRITICAL threshold: {self.MEMORY_CRITICAL}%)"
            )
            return "CRITICAL"
        elif percent_used >= self.MEMORY_WARNING:
            self.warnings.append(
                f"Memory: {percent_used}% used (WARNING threshold: {self.MEMORY_WARNING}%)"
            )
            return "WARNING HIGH"
        return "OK"

    def check_security_updates(self, update_text: str) -> bool:
        """
        Check if security updates are pending.
        Returns True if security updates detected.
        """
        security_keywords = ["security", "Security", "CVE", "critical", "important"]
        has_security = any(kw in update_text for kw in security_keywords)

        if has_security:
            self.warnings.append("Security updates available - patching recommended")

        return has_security

    def check_service_status(
        self, service_name: str, status: str, pid: str = ""
    ) -> str:
        """
        Check service status.
        Returns: 'running', 'stopped', 'error'
        """
        if status == "running" or (pid and pid != "-"):
            return "running"
        elif status == "not running" or pid == "-":
            return "stopped"
        else:
            self.warnings.append(f"Service {service_name}: unknown status '{status}'")
            return "error"

    def check_internet_connectivity(self, status: str) -> bool:
        """
        Check if internet is reachable.
        Returns True if connected.
        """
        if "OK" not in status and "successful" not in status:
            self.criticals.append("Internet connectivity: UNREACHABLE")
            return False
        return True

    def check_dns_resolution(self, status: str) -> bool:
        """
        Check if DNS resolution is working.
        Returns True if working.
        """
        if "OK" not in status and "FAILED" in status:
            self.warnings.append("DNS resolution: FAILED")
            return False
        return True

    def get_summary(self) -> Dict[str, List[str]]:
        """Get summary of all checks."""
        return {
            "critical": self.criticals,
            "warnings": self.warnings,
            "info": self.infos,
        }

    def has_issues(self) -> bool:
        """Return True if any warnings or criticals were found."""
        return len(self.warnings) > 0 or len(self.criticals) > 0

    def format_report(self) -> str:
        """Format threshold check results as text."""
        lines = []

        if self.criticals:
            lines.append("🔴 CRITICAL ISSUES:")
            for c in self.criticals:
                lines.append(f"  - {c}")
            lines.append("")

        if self.warnings:
            lines.append("🟡 WARNINGS:")
            for w in self.warnings:
                lines.append(f"  - {w}")
            lines.append("")

        if not self.criticals and not self.warnings:
            lines.append("✅ All checks passed - no threshold issues detected")

        return "\n".join(lines)


def parse_percentage(value_str: str) -> int:
    """Parse a percentage string to integer."""
    try:
        # Remove % sign if present
        clean = value_str.replace("%", "").strip()
        return int(float(clean))
    except (ValueError, TypeError):
        return 0


def check_thresholds(data: dict) -> ThresholdChecker:
    """
    Run all threshold checks on diagnostic data.
    Returns a ThresholdChecker with results.
    """
    checker = ThresholdChecker()
    sections = data.get("sections", {})

    # Check disk thresholds
    if "DISK" in sections:
        for key, value in sections["DISK"].items():
            if key.startswith("drive="):
                # Parse drive line
                parts = f"{key}={value}".split()
                drive_info = {}
                for part in parts:
                    if "=" in part:
                        k, v = part.split("=", 1)
                        drive_info[k] = v

                pct = parse_percentage(drive_info.get("percent", "0"))
                mount = drive_info.get("drive", "unknown")
                checker.check_disk(pct, mount)

    # Check memory thresholds
    if "MEMORY" in sections:
        mem = sections["MEMORY"]
        pct = parse_percentage(mem.get("percent_used", "0"))
        checker.check_memory(pct)

    # Check security updates
    if "UPDATES" in sections:
        upd = sections["UPDATES"]
        if "macos_updates" in upd:
            checker.check_security_updates(upd["macos_updates"])

    # Check internet connectivity
    if "NETWORK" in sections:
        net = sections["NETWORK"]
        if "internet_status" in net:
            checker.check_internet_connectivity(net["internet_status"])
        if "dns_resolution" in net:
            checker.check_dns_resolution(net["dns_resolution"])

    return checker
