# PR Command

Clean up code, add a changeset if needed, commit, push, and open a pull request — all in one step.

## Instructions

Follow these steps in order:

### 1. Code Review & Cleanup
- Review all unstaged and staged changes using `git status` and `git diff`
- Check for and fix: stray console.log statements, commented-out code, unused imports, formatting issues

### 2. Run Linter/Formatter (if available)
- Check for `package.json` scripts like `lint`, `format`, or `prettier`
- If found, run them and fix any errors

### 3. Generate Changeset (if applicable)
- Use the `generate-changeset` skill if the project has a `.changeset` directory

### 4. Stage Changes
- Stage relevant files by name — avoid `git add .` to prevent accidentally staging sensitive files

### 5. Commit Changes
- Analyze the staged diff and recent commit messages for style
- Write a concise commit message focused on the "why"
- Commit the staged changes

### 6. Push to Remote
- Push the current branch: `git push -u origin HEAD`

### 7. Generate Pull Request
- Use the `generate-pull-request` skill to create the PR

## Notes

- This command assumes you're on a feature branch. If on main/master, warn the user first.
- Skills used: `generate-changeset`, `generate-pull-request`
