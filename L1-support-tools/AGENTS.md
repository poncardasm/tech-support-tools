# L1 Support Tools

Monorepo for L1 support CLI tools. Each tool has platform-specific implementations.

**Current state:** Tools are in planning phase — only docs exist, no implementation code yet.

## Structure

```
NN-tool-name/
├── macos/docs/    # PRD.md, IMPLEMENTATION.md, TASKS.md
└── windows/docs/  # PRD.md, IMPLEMENTATION.md, TASKS.md
```

Tools are numbered 01-07 for ordering.

## Git Repository

**IMPORTANT:** This is a single monorepo. **Do NOT create separate `.git` directories** inside tool folders or their subdirectories. Always commit to the main repository at the root level:

```bash
# Correct: Run git commands from the repo root
cd /Users/mchael/gh-repo/projects/L1-support-tools
git add 01-ticket-triage-cli/windows/
git commit -m "feat: add Windows ticket-triage implementation"

# Wrong: Do NOT do this
cd 01-ticket-triage-cli/windows/ && git init   # ❌ NEVER do this
git add 01-ticket-triage-cli/windows/.git       # ❌ NEVER commit nested repos
```

## Tool Stack

All tools use:

- Python 3.10+
- Click for CLI
- pytest for tests
- Homebrew (macOS) for distribution

## Commands

Per tool (inside tool directory after implementation):

```bash
pip install -e .          # dev install
pytest tests/ -v          # run tests
```

## Config Locations

macOS: `~/.config/<tool-name>/`
Windows: `%APPDATA%\<tool-name>\`

## Git Workflow

Use conventional commits standard for all commits:

```
<type>: <description>

Examples:
feat: add ticket-triage-cli project scaffold
chore: add comprehensive .gitignore with OS temp files
docs: update AGENTS.md with git workflow section
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Docs Purpose

- PRD.md — product spec
- IMPLEMENTATION.md — technical plan
- TASKS.md — phased checklist
