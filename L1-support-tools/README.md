# L1 Support Tools

A monorepo of CLI tools designed to streamline Level 1 IT support workflows. These tools help reduce decision fatigue, eliminate repetitive clicks in admin UIs, and ensure clean handoffs between L1 and L2 support tiers.

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)
![pytest](https://img.shields.io/badge/pytest-0A9EDC?logo=pytest&logoColor=white)
![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?logo=homebrew&logoColor=black)

## Overview

This repository contains platform-specific implementations of 7 specialized CLI tools for common L1 support tasks. Each tool focuses on a specific pain point in the support workflow — from ticket triage to user provisioning — with both macOS and Windows versions.

**Tech Stack:**

- Python 3.10+
- PowerShell 5.1+
- Click (CLI framework) / Click (via Python on Windows)
- pytest (testing)
- Homebrew (macOS distribution)

## Tools

| Tool                         | Description                                                                                                                                                                                                                                      | Directory                                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| **Ticket Triage CLI**        | Analyzes raw ticket text and returns structured triage results: category, priority, suggested actions, escalation guidance, and related KB links. Reduces decision fatigue by acting like a senior L1 analyst looking over the agent's shoulder. | [`01-ticket-triage-cli/`](./01-ticket-triage-cli/)       |
| **Log Dump Parser**          | Ingests raw log files (Syslog, journald, JSON, Apache/Nginx, Docker) and returns cleaned, structured summaries of errors and warnings grouped by frequency. No more scrolling through 10,000 lines to find what's actually wrong.                | [`02-log-dump-parser/`](./02-log-dump-parser/)           |
| **Runbook Automation**       | Manages markdown-based runbooks with embedded executable steps. Write procedures in Markdown, then execute them sequentially with one command — no more copy-paste from wikis into terminals.                                                    | [`03-runbook-automation/`](./03-runbook-automation/)     |
| **Diagnostic Collector**     | One-command system info gatherer for L1/L2 handoffs. Collects hardware info, disk space, running services, recent errors, memory, CPU, and installed packages into a clean HTML or Markdown report.                                              | [`04-diagnostic-collector/`](./04-diagnostic-collector/) |
| **IT Knowledge CLI**         | Offline-capable Q&A CLI for common IT questions. Uses local embeddings to answer "how do I reset an Outlook profile?" instantly without leaving the terminal or making web searches. Ticket data never leaves the network.                       | [`05-it-knowledge-cli/`](./05-it-knowledge-cli/)         |
| **Bulk Action Runner**       | CSV-powered bulk operations for tasks like password resets, group additions, and mailbox enables. Upload a CSV of users, pick an operation, and execute in batch — replacing painful HelpDesk GUI workflows.                                     | [`06-bulk-action-runner/`](./06-bulk-action-runner/)     |
| **AD/User Provisioning CLI** | Single-command user provisioning for AD accounts, group memberships, and mailboxes. One command replaces 10 clicks in the slow Admin Center UI, with clean confirmation output and loud errors on failure.                                       | [`07-ad-provisioning-cli/`](./07-ad-provisioning-cli/)   |

## Repository Structure

```
L1-support-tools/
├── 01-ticket-triage-cli/
│   ├── macos/             # Python implementation
│   │   ├── ticket_triage/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # Python implementation
│       ├── ticket_triage/
│       ├── tests/
│       └── Formula/
├── 02-log-dump-parser/
│   ├── macos/             # Python implementation
│   │   ├── src/log_parse/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # Python implementation
│       ├── src/log_parse/
│       ├── tests/
│       └── Formula/
├── 03-runbook-automation/
│   ├── macos/             # Python implementation
│   │   ├── runbook/
│   │   ├── runbooks/
│   │   └── Formula/
│   └── windows/           # PowerShell implementation
│       ├── public/
│       ├── private/
│       └── runbooks/
├── 04-diagnostic-collector/
│   ├── macos/             # Python implementation
│   │   ├── diag/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # PowerShell implementation
│       ├── formatters/
│       ├── modules/
│       └── tests/
├── 05-it-knowledge-cli/
│   ├── macos/             # Python implementation
│   │   ├── it_kb/
│   │   ├── kb/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # Python implementation
│       ├── it_kb/
│       ├── kb/
│       └── build/
├── 06-bulk-action-runner/
│   ├── macos/             # Python implementation
│   │   ├── bulk_runner/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # PowerShell implementation
│       ├── public/
│       ├── private/
│       └── tests/
├── 07-ad-provisioning-cli/
│   ├── macos/             # Python implementation
│   │   ├── ad_provision/
│   │   ├── tests/
│   │   └── Formula/
│   └── windows/           # PowerShell implementation
│       ├── public/
│       ├── private/
│       └── config/
├── README.md              # This file
└── AGENTS.md              # Development guidelines
```

Each tool directory contains platform-specific documentation in `docs/` subdirectories:

- `PRD.md` — Product requirements and functional spec
- `IMPLEMENTATION.md` — Technical implementation plan
- `TASKS.md` — Phased development checklist

## Current State

**Status:** Implementation complete — all 7 tools now have working implementations for both macOS and Windows platforms.

Each tool includes:
- Full source code (Python for macOS, Python/PowerShell for Windows)
- Test suites with pytest/Pester
- Homebrew formulas (macOS)
- Sample data and configuration files where applicable
- Documentation (PRD.md, IMPLEMENTATION.md, TASKS.md) in `docs/` subdirectories

## Development

### Per Tool Commands (after implementation)

```bash
cd 01-ticket-triage-cli/macos/
pip install -e .          # dev install
pytest tests/ -v          # run tests
```

### Config Locations

- **macOS:** `~/.config/<tool-name>/`
- **Windows:** `%APPDATA%\<tool-name>\`

### Git Workflow

This is a single monorepo. All git operations should be run from the repository root:

```bash
# Correct: Commit from root
git add 01-ticket-triage-cli/windows/
git commit -m "feat: add Windows ticket-triage implementation"
```

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new features
- `fix:` — bug fixes
- `docs:` — documentation changes
- `chore:` — maintenance tasks
- `test:` — test additions/changes
- `refactor:` — code refactoring

## Author

**Mchael Poncardas**

- Website: [www.poncardas.com](https://www.poncardas.com)
- Email: [m@poncardas.com](mailto:m@poncardas.com)
- LinkedIn: [https://www.linkedin.com/in/poncardas/](https://www.linkedin.com/in/poncardas/)
- GitHub: [https://github.com/poncardasm](https://github.com/poncardasm)
