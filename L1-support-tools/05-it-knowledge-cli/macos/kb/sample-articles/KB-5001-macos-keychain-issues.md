---
id: KB-5001
title: macOS Keychain Certificate Issues
category: security
products: [macos, keychain]
last_updated: 2024-04-10
---

# macOS Keychain Certificate Issues

## Problem

Apps repeatedly prompt for passwords, certificates show as invalid, or SSO isn't working properly.

## Common Causes

- Expired certificates in Keychain
- Duplicate entries
- Corrupted keychain database
- Wrong default keychain

## Solutions

### Reset Default Keychain

**Warning**: This will remove saved passwords.

1. Open **Keychain Access** (Applications > Utilities)
2. Go to **Keychain Access** > **Preferences**
3. Click **Reset Default Keychains**
4. Enter your new password
5. Restart your Mac

### Delete Specific Certificates

1. Open **Keychain Access**
2. Select **System** or **login** keychain
3. Search for the problematic certificate
4. Right-click → **Delete**
5. Re-authenticate to re-download

### Using Command Line

```bash
# List all certificates
security find-certificate -a -p

# Delete a specific certificate by name
security delete-certificate -c "Certificate Name" ~/Library/Keychains/login.keychain-db

# Delete Microsoft-specific entries
security delete-internet-password -s "login.microsoftonline.com"
security delete-generic-password -s "MicrosoftOffice15"

# Reset NTLM credentials
sudo kdestroy -A
```

### Repair Keychain Database

```bash
# Check keychain integrity
security verify-keychain ~/Library/Keychains/login.keychain-db

# Create new keychain if corrupted
security create-keychain -p "password" ~/Library/Keychains/new.keychain-db
```

## Office-Specific Fix

If Microsoft apps keep prompting for credentials:

1. Quit all Office apps
2. Delete these from Keychain:
   - `MicrosoftOffice15*` entries
   - `Microsoft Office*` entries
   - `adal*` entries
3. Delete: `~/Library/Group Containers/UBF8T346G9.Office/`
4. Restart apps and re-authenticate

## Related

- KB-1001: Set Up 2FA for Microsoft Entra ID
- KB-5002: Troubleshooting macOS SSO
