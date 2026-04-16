"""
Output formatters for diagnostic collector
"""

import click
import sys
import json
import re
from datetime import datetime
from html import escape


def parse_collector_output(raw: str) -> dict:
    """Parse the raw collector.sh output into a structured dictionary."""
    result = {
        "collected_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "hostname": "unknown",
        "sections": {},
    }

    current_section = None
    current_multiline = None
    multiline_buffer = []

    for line in raw.split("\n"):
        line = line.rstrip()

        # Section header
        if line.startswith("=== ") and line.endswith(" ==="):
            # Save any pending multiline
            if current_multiline and multiline_buffer:
                result["sections"][current_section][current_multiline] = "\n".join(
                    multiline_buffer
                )
                multiline_buffer = []
                current_multiline = None

            current_section = line.strip("= ")
            result["sections"][current_section] = {}
            continue

        if not current_section:
            continue

        # Multiline value start (<<EOF)
        if "<<EOF" in line:
            key = line.split("<<EOF")[0].strip()
            current_multiline = key
            multiline_buffer = []
            continue

        # Multiline value end (EOF)
        if line == "EOF" and current_multiline:
            result["sections"][current_section][current_multiline] = "\n".join(
                multiline_buffer
            )
            multiline_buffer = []
            current_multiline = None
            continue

        # Collect multiline content
        if current_multiline:
            multiline_buffer.append(line)
            continue

        # Simple key=value pairs
        if "=" in line and not line.startswith(" "):
            parts = line.split("=", 1)
            if len(parts) == 2:
                key, value = parts
                result["sections"][current_section][key] = value

                # Extract hostname for report title
                if key == "hostname":
                    result["hostname"] = value

    # Save any pending multiline at end
    if current_multiline and multiline_buffer:
        result["sections"][current_section][current_multiline] = "\n".join(
            multiline_buffer
        )

    return result


def format_markdown(data: dict) -> str:
    """Format the parsed data as Markdown."""
    hostname = escape(data.get("hostname", "unknown"))
    timestamp = data.get("collected_at", "unknown")

    md = f"# Diagnostic Report — {hostname}\n"
    md += f"Collected: {timestamp}\n\n"

    # System section
    if "SYSTEM" in data["sections"]:
        sys = data["sections"]["SYSTEM"]
        md += "## System\n"
        md += f"- **Hostname:** {sys.get('hostname', 'N/A')}\n"
        md += f"- **OS:** {sys.get('os_name', 'N/A')} {sys.get('os_version', 'N/A')} ({sys.get('os_build', 'N/A')})\n"
        md += f"- **Model:** {sys.get('model', 'N/A')}\n"
        md += f"- **Chip:** {sys.get('chip', 'N/A')}\n"
        md += f"- **Memory:** {sys.get('total_memory', 'N/A')}\n"
        md += f"- **Uptime:** {sys.get('uptime', 'N/A')}\n"
        md += f"- **Current User:** {sys.get('current_user', 'N/A')}\n\n"

    # Memory section
    if "MEMORY" in data["sections"]:
        mem = data["sections"]["MEMORY"]
        md += "## CPU / Memory\n"
        total_mb = mem.get("total_mb", 0)
        used_mb = mem.get("used_mb", 0)
        percent = mem.get("percent_used", 0)
        status = mem.get("status", "OK")

        total_gb = int(total_mb) / 1024 if total_mb else 0
        used_gb = int(used_mb) / 1024 if used_mb else 0

        status_tag = ""
        if status == "CRITICAL":
            status_tag = " 🔴 **CRITICAL**"
        elif status == "WARNING HIGH":
            status_tag = " 🟡 **WARNING HIGH**"

        md += f"- **Memory:** {used_gb:.1f} GB / {total_gb:.1f} GB used ({percent}%){status_tag}\n"

        if "top_processes" in mem:
            md += "\n**Top Memory Consumers:**\n"
            md += "```\n"
            md += mem["top_processes"]
            md += "\n```\n"
        md += "\n"

    # Disk section
    if "DISK" in data["sections"]:
        md += "## Disk\n"
        disk_data = data["sections"]["DISK"]

        # Parse disk lines - they are keys in the dict
        for key, value in disk_data.items():
            if key.startswith("drive="):
                # Parse drive line: drive=/ used=100G total=500G percent=20 status=OK
                parts = f"{key}={value}".split()
                drive_info = {}
                for part in parts:
                    if "=" in part:
                        k, v = part.split("=", 1)
                        drive_info[k] = v

                drive = drive_info.get("drive", "unknown")
                used = drive_info.get("used", "N/A")
                total = drive_info.get("total", "N/A")
                pct = drive_info.get("percent", "N/A")
                status = drive_info.get("status", "OK")

                status_tag = ""
                if status == "CRITICAL":
                    status_tag = " 🔴 **CRITICAL**"
                elif status == "WARNING HIGH":
                    status_tag = " 🟡 **WARNING HIGH**"

                md += f"- **{drive}:** {used} / {total} ({pct}%){status_tag}\n"
        md += "\n"

    # Network section
    if "NETWORK" in data["sections"]:
        net = data["sections"]["NETWORK"]
        md += "## Network\n"

        # Collect interfaces
        interfaces = []
        for key, value in net.items():
            if key.startswith("interface="):
                iface = key.replace("interface=", "")
                interfaces.append(f"{iface}: {value}")

        for iface in interfaces:
            md += f"- **Interface:** {iface}\n"

        if "gateway" in net:
            md += f"- **Gateway:** {net['gateway']}\n"

        # DNS servers
        dns_servers = []
        for key, value in net.items():
            if key == "dns":
                dns_servers.append(value)
            elif key.startswith("dns="):
                dns_servers.append(key.replace("dns=", ""))

        if dns_servers:
            md += f"- **DNS:** {', '.join(dns_servers)}\n"

        if "internet_status" in net:
            md += f"- **Internet:** {net['internet_status']}\n"
        if "dns_resolution" in net:
            md += f"- **DNS Resolution:** {net['dns_resolution']}\n"
        md += "\n"

    # Services section
    if "SERVICES" in data["sections"]:
        svc = data["sections"]["SERVICES"]
        md += "## Running Services\n"

        services = []
        for key, value in svc.items():
            if key.startswith("service="):
                # Parse: service=com.apple.Dock.server pid=123 status=running
                parts = f"{key}={value}".split()
                svc_info = {}
                for part in parts:
                    if "=" in part:
                        k, v = part.split("=", 1)
                        svc_info[k] = v

                svc_name = svc_info.get("service", "unknown")
                status = svc_info.get("status", "unknown")

                status_emoji = "🟢" if status == "running" else "⚪"
                services.append(f"{status_emoji} `{svc_name}` — {status}")

        for svc in services[:20]:  # Limit to 20
            md += f"- {svc}\n"

        if "homebrew_services" in svc:
            md += "\n**Homebrew Services:**\n```\n"
            md += svc["homebrew_services"]
            md += "\n```\n"
        md += "\n"

    # Logs section
    if "LOGS" in data["sections"]:
        logs = data["sections"]["LOGS"]
        md += "## Recent Errors (last 24h, up to 50)\n"
        if "recent_errors" in logs and logs["recent_errors"].strip():
            md += "```\n"
            md += logs["recent_errors"]
            md += "\n```\n"
        else:
            md += "_No recent errors or unable to retrieve (may require Full Disk Access)_\n"
        md += "\n"

    # Packages section
    if "PACKAGES" in data["sections"]:
        pkg = data["sections"]["PACKAGES"]
        md += "## Installed Packages\n"
        md += f"- **Homebrew:** {pkg.get('homebrew_count', 'N/A')} packages\n"
        md += f"- **pip:** {pkg.get('pip_count', 'N/A')} packages\n"
        md += f"- **npm:** {pkg.get('npm_count', 'N/A')} packages\n"

        if "homebrew_packages" in pkg:
            md += "\n**Homebrew Package List (first 20):**\n"
            md += "```\n"
            md += pkg["homebrew_packages"]
            md += "\n```\n"
        md += "\n"

    # Updates section
    if "UPDATES" in data["sections"]:
        upd = data["sections"]["UPDATES"]
        md += "## Pending Updates\n"

        macos_updates = upd.get("macos_updates", "").strip()
        if macos_updates and "No new software available" not in macos_updates:
            md += "### macOS Updates\n"
            md += "```\n"
            md += macos_updates
            md += "\n```\n"
        else:
            md += "- **macOS:** No updates available\n"

        if "homebrew_outdated" in upd:
            md += "\n### Homebrew Outdated Packages\n"
            md += "```\n"
            md += upd["homebrew_outdated"]
            md += "\n```\n"
        md += "\n"

    # Users section
    if "USERS" in data["sections"]:
        usr = data["sections"]["USERS"]
        md += "## User Activity\n"

        if "active_users" in usr and usr["active_users"].strip():
            md += "### Active Users\n```\n"
            md += usr["active_users"]
            md += "\n```\n"

        if "recent_logins" in usr and usr["recent_logins"].strip():
            md += "\n### Recent Logins (last 10)\n```\n"
            md += usr["recent_logins"]
            md += "\n```\n"
        md += "\n"

    return md


def format_html(data: dict) -> str:
    """Format the parsed data as HTML report."""
    hostname = escape(data.get("hostname", "unknown"))
    timestamp = escape(data.get("collected_at", "unknown"))

    def status_badge(status):
        if status == "CRITICAL":
            return '<span style="background:#dc3545;color:white;padding:2px 8px;border-radius:4px;font-weight:bold;">CRITICAL</span>'
        elif status == "WARNING HIGH":
            return '<span style="background:#ffc107;color:black;padding:2px 8px;border-radius:4px;font-weight:bold;">WARNING HIGH</span>'
        return '<span style="background:#28a745;color:white;padding:2px 8px;border-radius:4px;">OK</span>'

    html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Diagnostic Report — {hostname}</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 900px; margin: 40px auto; padding: 20px; background: #f5f5f5; }}
        h1 {{ color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }}
        h2 {{ color: #555; border-bottom: 2px solid #ddd; padding-bottom: 5px; margin-top: 30px; }}
        h3 {{ color: #666; margin-top: 20px; }}
        .meta {{ color: #666; font-style: italic; margin-bottom: 20px; }}
        .section {{ background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        pre {{ background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; font-size: 12px; border: 1px solid #e9ecef; }}
        ul {{ line-height: 1.8; }}
        .ok {{ color: #28a745; }}
        .warning {{ color: #ffc107; font-weight: bold; }}
        .critical {{ color: #dc3545; font-weight: bold; }}
    </style>
</head>
<body>
    <h1>🔧 Diagnostic Report — {hostname}</h1>
    <div class="meta">Collected: {timestamp}</div>
"""

    # System section
    if "SYSTEM" in data["sections"]:
        sys = data["sections"]["SYSTEM"]
        html += '<div class="section">\n<h2>🖥️ System</h2>\n<ul>\n'
        html += f"<li><strong>Hostname:</strong> {escape(sys.get('hostname', 'N/A'))}</li>\n"
        html += f"<li><strong>OS:</strong> {escape(sys.get('os_name', 'N/A'))} {escape(sys.get('os_version', 'N/A'))} ({escape(sys.get('os_build', 'N/A'))})</li>\n"
        html += f"<li><strong>Model:</strong> {escape(sys.get('model', 'N/A'))}</li>\n"
        html += f"<li><strong>Chip:</strong> {escape(sys.get('chip', 'N/A'))}</li>\n"
        html += f"<li><strong>Memory:</strong> {escape(sys.get('total_memory', 'N/A'))}</li>\n"
        html += (
            f"<li><strong>Uptime:</strong> {escape(sys.get('uptime', 'N/A'))}</li>\n"
        )
        html += f"<li><strong>Current User:</strong> {escape(sys.get('current_user', 'N/A'))}</li>\n"
        html += "</ul>\n</div>\n"

    # Memory section
    if "MEMORY" in data["sections"]:
        mem = data["sections"]["MEMORY"]
        html += '<div class="section">\n<h2>💾 CPU / Memory</h2>\n'

        total_mb = int(mem.get("total_mb", 0) or 0)
        used_mb = int(mem.get("used_mb", 0) or 0)
        percent = mem.get("percent_used", 0)
        status = mem.get("status", "OK")

        total_gb = total_mb / 1024
        used_gb = used_mb / 1024

        html += "<ul>\n"
        html += f"<li><strong>Memory:</strong> {used_gb:.1f} GB / {total_gb:.1f} GB used ({percent}%) {status_badge(status)}</li>\n"
        html += "</ul>\n"

        if "top_processes" in mem:
            html += "<h3>Top Memory Consumers</h3>\n<pre>"
            html += escape(mem["top_processes"])
            html += "</pre>\n"
        html += "</div>\n"

    # Disk section
    if "DISK" in data["sections"]:
        html += '<div class="section">\n<h2>💿 Disk</h2>\n<ul>\n'
        disk_data = data["sections"]["DISK"]

        for key, value in disk_data.items():
            if key.startswith("drive="):
                parts = f"{key}={value}".split()
                drive_info = {}
                for part in parts:
                    if "=" in part:
                        k, v = part.split("=", 1)
                        drive_info[k] = v

                drive = escape(drive_info.get("drive", "unknown"))
                used = escape(drive_info.get("used", "N/A"))
                total = escape(drive_info.get("total", "N/A"))
                pct = escape(drive_info.get("percent", "N/A"))
                status = drive_info.get("status", "OK")

                html += f"<li><strong>{drive}:</strong> {used} / {total} ({pct}%) {status_badge(status)}</li>\n"

        html += "</ul>\n</div>\n"

    # Network section
    if "NETWORK" in data["sections"]:
        net = data["sections"]["NETWORK"]
        html += '<div class="section">\n<h2>🌐 Network</h2>\n<ul>\n'

        for key, value in net.items():
            if key.startswith("interface="):
                iface = escape(key.replace("interface=", ""))
                html += (
                    f"<li><strong>Interface {iface}:</strong> {escape(value)}</li>\n"
                )

        if "gateway" in net:
            html += f"<li><strong>Gateway:</strong> {escape(net['gateway'])}</li>\n"

        dns_servers = []
        for key, value in net.items():
            if key == "dns":
                dns_servers.append(value)
            elif key.startswith("dns="):
                dns_servers.append(key.replace("dns=", ""))

        if dns_servers:
            html += f"<li><strong>DNS:</strong> {escape(', '.join(dns_servers))}</li>\n"

        if "internet_status" in net:
            status_class = "ok" if "OK" in net["internet_status"] else "critical"
            html += f'<li><strong>Internet:</strong> <span class="{status_class}">{escape(net["internet_status"])}</span></li>\n'

        html += "</ul>\n</div>\n"

    # Services section
    if "SERVICES" in data["sections"]:
        svc = data["sections"]["SERVICES"]
        html += '<div class="section">\n<h2>⚙️ Running Services</h2>\n<ul>\n'

        count = 0
        for key, value in svc.items():
            if key.startswith("service="):
                parts = f"{key}={value}".split()
                svc_info = {}
                for part in parts:
                    if "=" in part:
                        k, v = part.split("=", 1)
                        svc_info[k] = v

                svc_name = escape(svc_info.get("service", "unknown"))
                status = svc_info.get("status", "unknown")
                status_class = "ok" if status == "running" else ""

                html += f'<li><code>{svc_name}</code> — <span class="{status_class}">{status}</span></li>\n'
                count += 1
                if count >= 20:
                    break

        html += "</ul>\n"

        if "homebrew_services" in svc:
            html += "<h3>Homebrew Services</h3><pre>"
            html += escape(svc["homebrew_services"])
            html += "</pre>"

        html += "</div>\n"

    # Logs section
    if "LOGS" in data["sections"]:
        logs = data["sections"]["LOGS"]
        html += '<div class="section">\n<h2>📋 Recent Errors (last 24h)</h2>\n'
        if "recent_errors" in logs and logs["recent_errors"].strip():
            html += "<pre>"
            html += escape(logs["recent_errors"])
            html += "</pre>\n"
        else:
            html += "<p><em>No recent errors or unable to retrieve (may require Full Disk Access)</em></p>\n"
        html += "</div>\n"

    # Packages section
    if "PACKAGES" in data["sections"]:
        pkg = data["sections"]["PACKAGES"]
        html += '<div class="section">\n<h2>📦 Installed Packages</h2>\n<ul>\n'
        html += f"<li><strong>Homebrew:</strong> {escape(str(pkg.get('homebrew_count', 'N/A')))} packages</li>\n"
        html += f"<li><strong>pip:</strong> {escape(str(pkg.get('pip_count', 'N/A')))} packages</li>\n"
        html += f"<li><strong>npm:</strong> {escape(str(pkg.get('npm_count', 'N/A')))} packages</li>\n"
        html += "</ul>\n"

        if "homebrew_packages" in pkg:
            html += "<h3>Homebrew Packages (first 20)</h3><pre>"
            html += escape(pkg["homebrew_packages"])
            html += "</pre>"

        html += "</div>\n"

    # Updates section
    if "UPDATES" in data["sections"]:
        upd = data["sections"]["UPDATES"]
        html += '<div class="section">\n<h2>🔄 Pending Updates</h2>\n'

        macos_updates = upd.get("macos_updates", "").strip()
        if macos_updates and "No new software available" not in macos_updates:
            html += "<h3>macOS Updates</h3><pre>"
            html += escape(macos_updates)
            html += "</pre>"
        else:
            html += "<p><strong>macOS:</strong> No updates available</p>\n"

        if "homebrew_outdated" in upd:
            html += "<h3>Homebrew Outdated</h3><pre>"
            html += escape(upd["homebrew_outdated"])
            html += "</pre>"

        html += "</div>\n"

    # Users section
    if "USERS" in data["sections"]:
        usr = data["sections"]["USERS"]
        html += '<div class="section">\n<h2>👥 User Activity</h2>\n'

        if "active_users" in usr and usr["active_users"].strip():
            html += "<h3>Active Users</h3><pre>"
            html += escape(usr["active_users"])
            html += "</pre>"

        if "recent_logins" in usr and usr["recent_logins"].strip():
            html += "<h3>Recent Logins (last 10)</h3><pre>"
            html += escape(usr["recent_logins"])
            html += "</pre>"

        html += "</div>\n"

    html += "</body>\n</html>"
    return html


def format_json(data: dict) -> str:
    """Format the parsed data as JSON."""
    return json.dumps(data, indent=2)


@click.command()
@click.option("--json", "output_json", is_flag=True, help="Output as JSON")
@click.option("--html", "output_html", is_flag=True, help="Output as HTML")
@click.option(
    "--markdown", "output_markdown", is_flag=True, help="Output as Markdown (default)"
)
def format_output(output_json, output_html, output_markdown):
    """Format collector output from stdin."""
    raw = sys.stdin.read()
    data = parse_collector_output(raw)

    if output_json:
        print(format_json(data))
    elif output_html:
        print(format_html(data))
    else:
        print(format_markdown(data))


if __name__ == "__main__":
    format_output()
