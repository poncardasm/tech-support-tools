# AGENTS.md

Guidance for AI agents working in this repository. Follow every rule below when making changes, committing, or pushing code.

## Roles

### Commit & Push Agent

**Role:** Responsible for staging, committing, and pushing changes to the remote.
**Rules:**

- **Always use the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard** for every commit message.
- Commit message format:

  ```
  <type>(<optional scope>): <short summary>

  <optional body>

  <optional footer(s)>
  ```

- Allowed `<type>` values:
  - `feat` — a new feature
  - `fix` — a bug fix
  - `docs` — documentation-only changes
  - `style` — formatting, whitespace, missing semicolons (no code change)
  - `refactor` — code change that neither fixes a bug nor adds a feature
  - `perf` — performance improvement
  - `test` — adding or updating tests
  - `build` — changes to build system or dependencies
  - `ci` — CI configuration changes
  - `chore` — maintenance tasks that don't modify src or tests
  - `revert` — reverts a previous commit
- Use an optional `<scope>` to point at the affected area (e.g. `feat(windows): ...`, `docs(pre-reformat-backup): ...`).
- Keep the summary line in the **imperative mood**, **≤ 72 characters**, and **without a trailing period**.
- For breaking changes, append `!` after the type/scope (e.g. `feat(api)!: drop legacy flag`) **and** add a `BREAKING CHANGE:` footer explaining the impact.
- Reference issues/PRs in the footer using `Refs: #123` or `Closes: #123` when applicable.
- Group related changes into a single commit; split unrelated changes into separate commits.
- Before pushing: run any lint/format/test tasks relevant to the changed files and ensure the working tree is clean of unintended artifacts.
- Push with `git push` to the current branch; never force-push to `main`.

#### Examples

- `feat(windows): add pre-reformat backup batch script`
- `fix(windows): handle missing source folder without aborting`
- `docs(pre-reformat-backup): clarify marker file requirement`
- `chore: add .gitignore for OS temp files`
- `refactor(windows)!: rename marker file variable`

## General Agent Conduct

- Keep changes scoped to the task; do not drive-by-edit unrelated files.
- Update `docs/` when behavior or usage changes.
- Prefer small, reviewable commits over one large commit.
- Do not commit generated artifacts, logs, or secrets (see `.gitignore`).
