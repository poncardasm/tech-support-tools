---
id: KB-3001
title: VPN DNS Override Configuration (macOS)
category: networking
products: [vpn, macos]
last_updated: 2024-03-15
---

# VPN DNS Override Configuration (macOS)

## Problem

VPN connection overrides local DNS settings, preventing access to internal resources.

## Solution

### Method 1: Configure VPN DNS in Network Preferences

1. Open **System Settings** → **Network**
2. Select your VPN connection
3. Click **Details**
4. Go to **DNS** tab
5. Click **+** to add DNS servers:
   - Primary: `10.0.0.1` (your internal DNS)
   - Secondary: `8.8.8.8` (Google DNS as fallback)
6. Click **OK**

### Method 2: Using scutil (Command Line)

```bash
# Show current DNS configuration
scutil --dns

# Add DNS for specific service
sudo networksetup -setdnsservers "Your VPN Service" 10.0.0.1 8.8.8.8

# Verify
scutil --dns
```

### Method 3: Edit /etc/resolver (Per-Domain DNS)

Create a resolver file for your company domain:

```bash
sudo mkdir -p /etc/resolver
sudo tee /etc/resolver/company.local << EOF
nameserver 10.0.0.1
nameserver 10.0.0.2
domain company.local
search_order 1
timeout 5
EOF
```

## Verification

Test DNS resolution:

```bash
# Using dig
 dig intranet.company.local

# Using nslookup
nslookup intranet.company.local

# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## Related

- KB-3002: Windows VPN DNS Configuration
- KB-3003: Troubleshooting VPN Connectivity
