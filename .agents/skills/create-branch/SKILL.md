---
name: create-branch
description: Create a new git branch from main/master with a maximum of 17 characters. Use when the user asks to create a branch, start new work, begin a feature/fix, work on a ticket, or start implementing something. Also use when the user says things like "let's begin", "new task", or "start fresh".
---

# Create Git Branch

## Instructions

1. Determine the main branch name by running `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
2. Ensure we're on the latest main branch:
   - Run `git fetch origin`
   - Run `git checkout <main-branch>`
   - Run `git pull origin <main-branch>`
3. Ask the user for a branch name OR infer from context if they've described what they're working on
4. Validate the branch name:
   - Must be 17 characters or less
   - Should use kebab-case (lowercase with hyphens)
   - Should be descriptive but concise
5. If the suggested/provided name is too long, offer a shortened version
6. Create the branch: `git checkout -b <branch-name>` — this switches to the new branch automatically
7. Push the branch to origin: `git push -u origin <branch-name>`
8. Confirm the branch was created, you're now on it, and it's tracking origin

## Branch Naming Guidelines

- Use kebab-case (e.g., `fix-auth-bug`, `add-user-api`)
- Keep it under 17 characters
- Be descriptive but concise
- Common prefixes: `feat-`, `fix-`, `docs-`, `refactor-`

## Examples

- `feat-oauth` (10 chars)
- `fix-login-error` (15 chars)
- `docs-readme` (11 chars)
- `refactor-auth` (13 chars)
