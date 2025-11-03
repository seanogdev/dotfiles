# Catchup Command

Read all files that have been changed in the current git branch to get up to speed with recent work.

## Instructions

1. Get the main branch name by running: `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
2. Get the list of all changed files compared to the main branch by running: `git diff --name-only $(git merge-base HEAD origin/$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'))`
3. Read each changed file using the Read tool to understand what modifications have been made
4. Provide a summary of the changes, organized by:
   - New files created
   - Modified files and what changed
   - Deleted files (if any)
5. Highlight any patterns or themes in the changes (e.g., "mostly configuration updates", "new feature implementation", etc.)

Be concise but thorough in your summary. Focus on what's functionally different, not just listing files.
