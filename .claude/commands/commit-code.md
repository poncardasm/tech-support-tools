# Commit Code

## 1. File Staging Rules

1. Stage all modified and newly created files.
2. Prompt the user to confirm whether they should be included.
   - If changes appear logically distinct (e.g., feature vs. refactor), ask how to segment commits before proceeding.

## 2. Commit Message Generation

1. Automatically generate a concise and descriptive message summarizing all staged changes.
2. Follow Conventional Commit syntax:
   - feat: – new feature
   - fix: – bug fix
   - refactor: – internal code change
   - docs: – documentation-only changes
   - chore: – maintenance or tooling updates
3. Do not include author, co-author, or metadata tags in the message.

## 3. Commit Execution

1. Display the complete, generated commit message for review.
2. Wait for the user to approve before finalizing the commit.

## 4. Commit Structure Guidance

1. If multiple logical commits are warranted, suggest possible commit groupings based on file or change context.
2. Proceed with the commit automatically using the generated message.
