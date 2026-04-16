---
id: KB-1001
title: Set Up 2FA for Microsoft Entra ID
category: security
products: [entra-id, microsoft-365, azure]
last_updated: 2024-01-20
---

# Set Up 2FA for Microsoft Entra ID

## Overview

Multi-factor authentication (MFA) adds an extra layer of security to your Microsoft 365 and Entra ID accounts.

## Setup Steps

### For End Users

1. **Sign in** to https://myaccount.microsoft.com
2. Click **Security info** → **+ Add sign-in method**
3. Choose your method:
   - **Microsoft Authenticator app** (recommended)
   - **Phone** (SMS or call)
   - **Alternate phone**
   - **Email**

#### Microsoft Authenticator Setup

1. Download **Microsoft Authenticator** from the App Store
2. In the portal, select **Authenticator app** → **Add**
3. Click **Next** to see QR code
4. Open Authenticator app → **+** → **Work or school account** → **Scan QR code**
5. Scan the QR code displayed on screen
6. Approve the test notification
7. Click **Next** → **Done**

### For Administrators

Enable MFA via Conditional Access:

1. Go to **Entra admin center** → **Identity** → **Conditional Access**
2. Click **+ Create new policy**
3. Name: "Require MFA for All Users"
4. **Assignments** → **Users** → Select users/groups
5. **Target resources** → **Cloud apps** → All cloud apps
6. **Access controls** → **Grant** → **Require multi-factor authentication**
7. **Enable policy**: **On**
8. Click **Create**

## Troubleshooting

### "You can't sign in here with a personal account"

- Use the URL: https://myworkaccount.microsoft.com
- Or click **Sign-in options** → **Sign in to an organization**

### Lost Authenticator Device

1. Contact IT to reset MFA
2. Sign in with backup method (SMS/phone)
3. Re-register Authenticator on new device

### macOS Keychain Issues

If you're repeatedly prompted for MFA on Mac:

```bash
# Reset Microsoft credentials in Keychain
security find-internet-password -s "login.microsoftonline.com" -d
# Delete old entries and re-authenticate
```

## Related Articles

- KB-1002: Troubleshooting MFA Issues
- KB-1003: MFA for Third-Party Apps
