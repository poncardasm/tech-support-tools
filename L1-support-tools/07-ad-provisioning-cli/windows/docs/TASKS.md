# AD/User Provisioning CLI — Tasks (Windows)

## Phase 1: Project Skeleton

- [x] Create PowerShell module structure (`ad-provision.psd1`, `ad-provision.psm1`)
- [x] Create `public/` directory with empty function files
- [x] Create `private/` directory for helper functions
- [x] Create `config/creds.env.example`
- [x] Verify `Import-Module ./ad-provision.psd1` works

---

## Phase 2: Microsoft Graph Integration

- [x] Install `Microsoft.Graph` and `ExchangeOnlineManagement` modules
- [x] Implement `Connect-GraphSession` in `private/`
- [x] Implement `Get-ProvisionConfig` for credential loading
- [x] Implement `Connect-ExchangeSession` for Exchange Online
- [x] Implement `New-TemporaryPassword` helper
- [x] Test connection to EntraID with certificate auth

---

## Phase 3: Core Commands

- [x] Implement `New-ADProvisionUser` in `public/`
- [x] Implement `Add-ADProvisionGroup` in `public/`
- [x] Implement `Enable-ADProvisionMailbox` in `public/`
- [x] Implement `Reset-ADProvisionPassword` in `public/`
- [x] Implement `Remove-ADProvisionUser` in `public/`
- [x] All commands support `-WhatIf` (dry-run)

---

## Phase 4: Output Formatting

- [x] Implement `Write-ProvisionOutput` helper
- [x] Consistent `[OK]`, `[FAIL]`, `[TEMP]`, `[WARN]` prefixes
- [x] Test output formatting in PowerShell console

---

## Phase 5: Testing

- [x] Create Pester test suite in `tests/`
- [x] Test `-WhatIf` mode for all commands
- [x] Mock Graph API calls for unit tests
- [x] Parameter validation tests
- [x] Helper function tests
- [x] Configuration loading tests

---

## Phase 6: Documentation

- [x] Write `README.md` with Windows-specific instructions
- [x] Document credential setup (certificate-based auth)
- [x] Add PowerShell command examples
- [x] Add troubleshooting section

---

## Phase 7: Installation

- [x] Create installation script for module deployment
- [x] Test module import on clean PowerShell session
- [x] Document module installation path

---

## Phase 8: Publish

- [x] Push to GitHub (committed to main branch)
- [ ] Optional: publish to PowerShell Gallery
