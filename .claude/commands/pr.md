# PR Command

A simple helper to clean up code, add a changeset if necessary (repo dependent), stage changes, and prepare a pull request.

## Instructions

Follow these steps in order:

### 1. Code Review & Cleanup
- Review all unstaged and staged changes using `git status` and `git diff`
- Check for common issues:
  - Console.log statements that should be removed
  - Commented-out code
  - TODO comments that should be addressed
  - Formatting issues
  - Unused imports
- Fix any issues found

### 2. Run Linter/Formatter (if available)
- Check if the project has a linter/formatter configured:
  - Look for `package.json` scripts like `lint`, `format`, or `prettier`
  - If found, run them: `npm run lint` or `npm run format`
- Fix any linting errors

### 3. Generate Changeset (if applicable)
- Use the `generate-changeset` skill to check if the project uses changesets
- If it does, generate an appropriate changeset file
- The changeset skill will handle checking for `.changeset` directory and following project patterns

### 4. Stage All Changes
- Run `git add .` to stage all changes including the new changeset (if created)

### 5. Commit Changes
- Use the `commit-helper` skill to generate an appropriate commit message
- Commit the staged changes

### 6. Push to Remote
- Push the current branch to remote: `git push origin HEAD`
- If the branch doesn't exist on remote, it will be created automatically
- Verify the push was successful

### 7. Generate Pull Request
- Use the `generate-pull-request` skill to create the PR
- The skill will:
  - Check for PR templates
  - Analyze git changes
  - Generate appropriate title and description
  - Create the PR using `gh pr create`

## Usage Notes

- This command assumes you're already on a feature branch
- If you're on main/master, warn the user and ask if they want to create a new branch first
- All skills used have their own error handling and will inform the user if something is not applicable

## Skills Used

1. `generate-changeset` - For adding changeset if project uses them
2. `commit-helper` - For generating appropriate commit messages
3. `generate-pull-request` - For creating the final PR

## Example Flow

```
/pr
→ Reviews code changes
→ Runs linter/formatter
→ Generates changeset (if .changeset/ exists)
→ Stages all changes
→ Generates commit message and commits
→ Pushes to remote
→ Creates pull request with comprehensive description
→ Returns PR URL
```
