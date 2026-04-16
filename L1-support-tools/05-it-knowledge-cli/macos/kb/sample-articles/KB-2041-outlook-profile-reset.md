---
id: KB-2041
title: Reset Outlook Profile (macOS)
category: email
products: [outlook, microsoft-365]
last_updated: 2024-02-01
---

# Reset Outlook Profile (macOS)

Steps to reset an Outlook profile on macOS:

1. Quit Outlook completely (Cmd+Q)
2. Open Finder → Go → Go to Folder
3. Enter: `~/Library/Group Containers/UBF8T346G9.Office/Outlook/`
4. Rename `Outlook 15 Profiles` folder to `Outlook 15 Profiles Backup`
5. Restart Outlook
6. Reconfigure your account

## Alternative: Using Outlook Profile Manager

1. Quit Outlook
2. Open Terminal
3. Run:
   ```bash
   /Applications/Microsoft\ Outlook.app/Contents/MacOS/Microsoft\ Outlook -createProfile
   ```

## Related Articles

- KB-2042: IMAP Setup Guide
- KB-1045: PST/OLM File Recovery

## Troubleshooting

If Outlook won't start after profile reset:
- Check Keychain Access for stale certificates
- Remove Outlook preferences: `~/Library/Preferences/com.microsoft.Outlook.plist`
