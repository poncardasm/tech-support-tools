---
id: KB-1045
title: PST File Recovery and Repair
category: email
products: [outlook, windows]
last_updated: 2024-02-10
---

# PST File Recovery and Repair

## Problem

Outlook PST file is corrupted or cannot be opened.

## Symptoms

- "Cannot start Microsoft Outlook" error
- "The set of folders cannot be opened"
- Outlook freezes or crashes on startup
- Missing emails or folders

## Solution: Using ScanPST

### Step 1: Locate ScanPST

**Outlook 2016/2019/365:**
```
C:\Program Files\Microsoft Office\root\Office16\SCANPST.EXE
```

**Outlook 2013:**
```
C:\Program Files\Microsoft Office\Office15\SCANPST.EXE
```

### Step 2: Locate Your PST File

1. Open Outlook → **File** → **Account Settings** → **Account Settings**
2. Click **Data Files** tab
3. Note the path to your PST file

Default locations:
- Windows 10/11: `%LOCALAPPDATA%\Microsoft\Outlook\`

### Step 3: Run ScanPST

1. Close Outlook completely
2. Run `SCANPST.EXE`
3. Click **Browse** and select your PST file
4. Click **Start** to scan
5. If errors found, check **Make a backup of scanned file before repairing**
6. Click **Repair**

### Step 4: Verify Repair

1. Open Outlook
2. Check if folders and emails are accessible

## Advanced Recovery

### Using Previous Versions (Shadow Copy)

1. Navigate to PST file folder
2. Right-click the PST file → **Properties** → **Previous Versions**
3. Select a version from before the corruption
4. Click **Restore**

### Third-Party Tools

- **Stellar Repair for Outlook**
- **DataNumen Outlook Repair**

## Prevention

- Keep PST files under 10GB
- Archive old emails regularly
- Use OST for Exchange accounts (auto-recoverable)
- Backup PST files periodically

## Related

- KB-2041: Reset Outlook Profile
- KB-2042: IMAP Setup Guide
