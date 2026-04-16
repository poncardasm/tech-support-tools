---
id: KB-3001
title: VPN DNS Override Configuration (Windows)
category: networking
products: [vpn, windows]
last_updated: 2024-03-15
---

# VPN DNS Override Configuration (Windows)

## Problem

VPN connection overrides local DNS settings, preventing access to internal resources.

## Solution

### Method 1: Configure Split Tunneling

1. Open **Settings** → **Network & Internet** → **VPN**
2. Select your VPN connection → **Advanced options**
3. Under **IP settings**, click **Edit**
4. Set **DNS servers** to:
   - Primary: `10.0.0.1` (your internal DNS)
   - Secondary: `8.8.8.8` (Google DNS as fallback)
5. Check **Use default gateway on remote network**: **Off**

### Method 2: PowerShell Configuration

```powershell
# Get VPN connection name
$vpnName = "Your VPN Connection"

# Set DNS suffix
Set-VpnConnection -Name $vpnName -DnsSuffix "company.local"

# Configure split tunneling
Set-VpnConnection -Name $vpnName -SplitTunneling $True
```

### Method 3: hosts File Edit

Add to `C:\Windows\System32\drivers\etc\hosts`:

```
10.0.0.10    intranet.company.local
10.0.0.11    mail.company.local
```

## Verification

Run in Command Prompt:

```cmd
ipconfig /all
nslookup intranet.company.local
```

## Related

- KB-3002: macOS VPN DNS Configuration
- KB-3003: Troubleshooting VPN Connectivity
