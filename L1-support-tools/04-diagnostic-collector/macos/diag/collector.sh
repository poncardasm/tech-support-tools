#!/bin/bash
#
# Diagnostic Collector for macOS
# Collects system information for L1/L2 support handoffs
#

set -e

# Configuration
OUTPUT_FORMAT="${OUTPUT_FORMAT:-markdown}"
HOSTNAME_TAG="${HOSTNAME_TAG:-$(hostname)}"
UPLOAD_ENDPOINT="${UPLOAD_ENDPOINT:-}"

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo_error() { echo -e "${RED}$1${NC}"; }
echo_warning() { echo -e "${YELLOW}$1${NC}"; }
echo_success() { echo -e "${GREEN}$1${NC}"; }

# Collect system information
collect_system_info() {
    echo "=== SYSTEM ==="
    echo "hostname=$(hostname)"
    echo "os_name=$(sw_vers -productName 2>/dev/null || echo 'Unknown')"
    echo "os_version=$(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
    echo "os_build=$(sw_vers -buildVersion 2>/dev/null || echo 'Unknown')"
    
    # Hardware model
    local model=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Model Name/{for(i=3;i<=NF;i++)printf $i" "; print ""}' | sed 's/ *$//' || echo 'Unknown')
    echo "model=$model"
    
    # Chip/CPU info
    local chip=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Chip|Processor Name/{for(i=3;i<=NF;i++)printf $i" "; print ""}' | head -1 | sed 's/ *$//' || echo 'Unknown')
    echo "chip=$chip"
    
    # Total memory
    local mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    local mem_gb=$((mem_bytes / 1024 / 1024 / 1024))
    echo "total_memory=${mem_gb}GB"
    
    # Uptime
    local uptime_str=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//;s/ *$//' || echo 'Unknown')
    echo "uptime=$uptime_str"
    
    # Current user
    echo "current_user=$(whoami)"
    echo ""
}

# Collect disk information
collect_disk_info() {
    echo "=== DISK ==="
    df -h 2>/dev/null | awk 'NR>1 {
        if (NF >= 9) {
            used=$3
            total=$2
            pct=$5
            mount=$9
            gsub(/%/, "", pct)
            status="OK"
            if (pct > 90) status="CRITICAL"
            else if (pct > 80) status="WARNING HIGH"
            print "drive=" mount, "used=" used, "total=" total, "percent=" pct, "status=" status
        }
    }'
    echo ""
}

# Collect memory information
collect_memory_info() {
    echo "=== MEMORY ==="
    
    # Get memory stats from vm_stat
    local vm_stats=$(vm_stat 2>/dev/null)
    local page_size=$(vm_stat 2>/dev/null | awk '/page size/ {print $8}' || echo 4096)
    
    if [ -n "$vm_stats" ]; then
        local free_pages=$(echo "$vm_stats" | awk '/Pages free/ {print $3}' | tr -d '.')
        local active_pages=$(echo "$vm_stats" | awk '/Pages active/ {print $3}' | tr -d '.')
        local inactive_pages=$(echo "$vm_stats" | awk '/Pages inactive/ {print $3}' | tr -d '.')
        local wired_pages=$(echo "$vm_stats" | awk '/Pages wired/ {print $4}' | tr -d '.')
        local compressed_pages=$(echo "$vm_stats" | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')
        
        local free_mb=$((free_pages * page_size / 1024 / 1024))
        local active_mb=$((active_pages * page_size / 1024 / 1024))
        local inactive_mb=$((inactive_pages * page_size / 1024 / 1024))
        local wired_mb=$((wired_pages * page_size / 1024 / 1024))
        local compressed_mb=$((compressed_pages * page_size / 1024 / 1024))
        
        local used_mb=$((active_mb + inactive_mb + wired_mb + compressed_mb))
        local total_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}' || echo 0)
        
        if [ "$total_mb" -gt 0 ]; then
            local used_pct=$((used_mb * 100 / total_mb))
            local status="OK"
            if [ "$used_pct" -gt 90 ]; then status="CRITICAL"
            elif [ "$used_pct" -gt 80 ]; then status="WARNING HIGH"
            fi
            
            echo "total_mb=$total_mb"
            echo "used_mb=$used_mb"
            echo "free_mb=$free_mb"
            echo "wired_mb=$wired_mb"
            echo "compressed_mb=$compressed_mb"
            echo "percent_used=$used_pct"
            echo "status=$status"
        fi
    fi
    
    # Top memory consumers
    echo "top_processes<<EOF"
    top -l 1 -o mem -n 10 2>/dev/null | tail -n +13 | head -10 | awk '{printf "%-20s %s\n", $2, $8}' || echo "N/A"
    echo "EOF"
    echo ""
}

# Collect network information
collect_network_info() {
    echo "=== NETWORK ==="
    
    # Interfaces and IPs
    ifconfig 2>/dev/null | grep -E "^\w+:|inet " | while read line; do
        if echo "$line" | grep -q "^\w*:"; then
            iface=$(echo "$line" | cut -d: -f1)
        elif echo "$line" | grep -q "inet "; then
            ip=$(echo "$line" | awk '{print $2}')
            if [ -n "$iface" ] && [ -n "$ip" ]; then
                echo "interface=$iface ip=$ip"
            fi
        fi
    done
    
    # Default gateway
    local gateway=$(netstat -rn 2>/dev/null | grep default | head -1 | awk '{print $2}' || echo 'Unknown')
    echo "gateway=$gateway"
    
    # DNS servers
    scutil --dns 2>/dev/null | grep "nameserver" | awk '{print "dns="$3}' | sort -u | head -5
    
    # DNS resolution test
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "internet_status=OK (ping 8.8.8.8 successful)"
    else
        echo "internet_status=UNREACHABLE"
    fi
    
    # DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        echo "dns_resolution=OK"
    else
        echo "dns_resolution=FAILED"
    fi
    echo ""
}

# Collect running services
collect_services() {
    echo "=== SERVICES ==="
    
    # Launchctl services
    launchctl list 2>/dev/null | grep -v "^#" | awk 'NF>=3 {
        pid=$1
        status=$2
        service=$3
        if (pid == "-") state="not running"
        else state="running"
        print "service="service, "pid="pid, "status="state
    }' | head -20
    
    # Homebrew services (if available)
    if command -v brew >/dev/null 2>&1; then
        echo ""
        echo "homebrew_services<<EOF"
        brew services list 2>/dev/null || echo "None or error"
        echo "EOF"
    fi
    echo ""
}

# Collect recent errors from logs
collect_logs() {
    echo "=== LOGS ==="
    echo "recent_errors<<EOF"
    log show --predicate 'messageType == error' --last 1d 2>/dev/null | head -50 | tail -n +2 || echo "Unable to retrieve errors (may require permissions)"
    echo "EOF"
    echo ""
}

# Collect installed packages
collect_packages() {
    echo "=== PACKAGES ==="
    
    # Homebrew packages
    if command -v brew >/dev/null 2>&1; then
        local brew_count=$(brew list 2>/dev/null | wc -l | tr -d ' ')
        echo "homebrew_count=$brew_count"
        echo "homebrew_packages<<EOF"
        brew list 2>/dev/null | head -20 || echo "None"
        echo "EOF"
    else
        echo "homebrew_count=0 (not installed)"
    fi
    
    # pip packages
    if command -v pip >/dev/null 2>&1; then
        local pip_count=$(pip list 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')
        echo "pip_count=$pip_count"
    else
        echo "pip_count=0 (not installed)"
    fi
    
    # npm packages
    if command -v npm >/dev/null 2>&1; then
        local npm_count=$(npm list -g 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        echo "npm_count=$npm_count"
    else
        echo "npm_count=0 (not installed)"
    fi
    echo ""
}

# Collect update information
collect_updates() {
    echo "=== UPDATES ==="
    
    # macOS software updates
    echo "macos_updates<<EOF"
    softwareupdate --list 2>/dev/null || echo "Unable to check (may require permissions)"
    echo "EOF"
    
    # Homebrew outdated packages
    if command -v brew >/dev/null 2>&1; then
        echo ""
        echo "homebrew_outdated<<EOF"
        brew outdated 2>/dev/null || echo "None or error checking"
        echo "EOF"
    fi
    echo ""
}

# Collect active users
collect_users() {
    echo "=== USERS ==="
    echo "active_users<<EOF"
    who 2>/dev/null || echo "N/A"
    echo "EOF"
    echo ""
    echo "recent_logins<<EOF"
    last 2>/dev/null | head -10 || echo "N/A"
    echo "EOF"
    echo ""
}

# Main collection function
collect_all() {
    collect_system_info
    collect_disk_info
    collect_memory_info
    collect_network_info
    collect_services
    collect_logs
    collect_packages
    collect_updates
    collect_users
}

# Show usage
show_usage() {
    cat << 'EOF'
Usage: collector.sh [OPTIONS]

Options:
    --markdown          Output Markdown report (default)
    --html              Output HTML report
    --json              Output JSON report
    --host <name>       Tag the report with custom hostname
    --upload            Upload report to configured endpoint
    --help              Show this help message

Environment Variables:
    OUTPUT_FORMAT       Set default output format (markdown, html, json)
    UPLOAD_ENDPOINT     URL to upload reports to

Examples:
    ./collector.sh                    # Interactive markdown output
    ./collector.sh --html             # HTML report
    ./collector.sh --json --upload    # JSON report and upload
EOF
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --markdown)
                OUTPUT_FORMAT="markdown"
                ;;
            --html)
                OUTPUT_FORMAT="html"
                ;;
            --json)
                OUTPUT_FORMAT="json"
                ;;
            --host)
                shift
                HOSTNAME_TAG="$1"
                ;;
            --upload)
                UPLOAD=true
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Upload report to endpoint
upload_report() {
    local content="$1"
    local endpoint="${UPLOAD_ENDPOINT}"
    
    if [ -z "$endpoint" ]; then
        echo_error "Error: UPLOAD_ENDPOINT not set"
        return 1
    fi
    
    if command -v curl >/dev/null 2>&1; then
        local response=$(echo "$content" | curl -s -X POST -H "Content-Type: text/plain" --data-binary @- "$endpoint" 2>&1)
        if [ $? -eq 0 ]; then
            echo_success "Upload successful: $response"
        else
            echo_error "Upload failed: $response"
            return 1
        fi
    else
        echo_error "Error: curl not available for upload"
        return 1
    fi
}

# Main function
main() {
    parse_args "$@"
    
    # Collect all data
    local raw_output=$(collect_all)
    local formatted_output=""
    
    # Format output
    case "$OUTPUT_FORMAT" in
        json)
            formatted_output=$(echo "$raw_output" | python3 -m diag.formatters --json 2>/dev/null || echo "$raw_output")
            ;;
        html)
            formatted_output=$(echo "$raw_output" | python3 -m diag.formatters --html 2>/dev/null || echo "$raw_output")
            ;;
        markdown|*)
            formatted_output=$(echo "$raw_output" | python3 -m diag.formatters --markdown 2>/dev/null || echo "$raw_output")
            ;;
    esac
    
    # Output to stdout
    echo "$formatted_output"
    
    # Upload if requested
    if [ "${UPLOAD:-}" = "true" ]; then
        upload_report "$formatted_output"
    fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
