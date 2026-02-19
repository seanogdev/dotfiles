---
name: generate-pull-request
description: Generate a pull request using GitHub CLI following the project's pull request template.
---

# Rule: Generating a Pull Request

## Goal

To guide an AI assistant in creating a pull request using the GitHub CLI (`gh pr create`) that follows the project's pull request template and conventions.

## Process

1.  **Verify branch is pushed:**
    - Check that the current branch exists on remote: `git ls-remote --heads origin $(git branch --show-current)`
    - If not pushed, push the branch first: `git push origin HEAD`
    - This is required before creating a PR

2.  **Check for PR templates:** Look for pull request templates in common locations:
    - `.github/pull_request_template.md`
    - `.github/PULL_REQUEST_TEMPLATE.md`
    - `.github/PULL_REQUEST_TEMPLATE/*.md` (multiple templates)
    - `docs/pull_request_template.md`

3.  **Analyze the template:** If a template exists, read it to understand:
    - Required sections and format
    - What information is expected
    - Any checklists or specific requirements

4.  **Gather PR information:**
    - **Title:** Generate a clear, concise title summarizing the changes
    - **Description:** Analyze git changes to create a comprehensive description
    - **Changes summary:** List key changes, files modified, and functionality added/updated
    - **Related issues:** Check commit messages and branch name for issue references
    - **Testing:** Document what was tested
    - **Checklist items:** Complete any checklist items from the template

5.  **Analyze git state:**
    - Run `git status` to confirm there are changes to include
    - Run `git log origin/[base-branch]..HEAD` to see commits that will be in the PR
    - Run `git diff origin/[base-branch]...HEAD --stat` to get an overview of changes

6.  **Generate PR content:**
    - Fill in the template (if it exists) or use the default structure in [references/default-template.md](references/default-template.md)
    - Use markdown formatting for readability
    - Include code examples if relevant
    - Link to related issues, PRs, or documentation

7.  **Create the PR:**
    - Use `gh pr create --title "..." --body "..."`
    - For multi-line body content, use a heredoc for proper formatting:
      ```bash
      gh pr create --title "..." --body "$(cat <<'EOF'
      PR description here
      EOF
      )"
      ```
    - Default base branch is usually `main` or `master` unless specified otherwise

## Rules

1. **Always check for templates first** - Use the project's template if it exists
2. **Be thorough** - Include all relevant information about the changes
3. **Use present tense** - Write descriptions in present tense (e.g., "Adds feature" not "Added feature")
4. **Reference issues** - Link to related issues using GitHub's syntax (`Closes #123`, `Fixes #456`)
5. **Include testing info** - Always document what testing was performed
6. **Use heredoc for body** - For proper formatting of multi-line PR descriptions

## Example Command

```bash
gh pr create --title "Fix: Resolve button hover state in dark mode" --body "$(cat <<'EOF'
## Summary

Fixes the button hover state when the application is in dark mode.

## Changes

- Updated `Button.tsx` to use theme-aware hover colors
- Added dark mode test cases in `Button.test.tsx`

## Testing

- ✅ Manual testing in dark mode
- ✅ Unit tests pass
- ✅ Visual regression tests updated

## Related Issues

Closes #789

## Checklist

- [x] Tests added
- [x] Changeset added
- [x] No breaking changes
EOF
)"
```

