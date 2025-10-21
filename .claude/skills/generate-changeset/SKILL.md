---
name: generate-changeset
description: Generate a changeset file for the current changes following the changesets pattern used in the project.
---

# Rule: Generating a Changeset

## Goal

To guide an AI assistant in creating a changeset file that follows the [@changesets/cli](https://github.com/changesets/changesets) format. Changesets are markdown files with YAML frontmatter that describe what changed and will be used to generate changelogs and version bumps.

## Process

1.  **Check for existing changesets:** Look for a `.changeset` directory in the project to confirm the project uses changesets. If it doesn't exist, inform the user that the project doesn't appear to use changesets.

2.  **Analyze existing changesets:** Read 1-2 existing changeset files in `.changeset/` to understand the project's changeset pattern and style.

3.  **Determine packages to include:**
    - In a monorepo: Identify which package(s) were modified by checking `git status` or analyzing the changes
    - In a single-package repo: Use the package name from `package.json`

4.  **Generate changeset content:**
    - Create a markdown file with YAML frontmatter
    - **IMPORTANT:** AI tools should ONLY generate `patch` bump types, never `minor` or `major`
    - Write a single, clear sentence summary of the changes following the project's existing changeset style

5.  **Save the changeset:**
    - Generate a unique filename using the pattern: `[adjective]-[noun]-[verb].md` (e.g., `happy-lions-jump.md`)
    - Save to `.changeset/` directory
    - Inform the user that the changeset has been created and should be committed with their changes

## Changeset File Format

```markdown
---
"package-name": patch
---

Brief summary of the change in present tense

Optional additional details in markdown format explaining:
- What changed
- Why it changed
- How to update code if needed
```

For monorepos with multiple packages:

```markdown
---
"@scope/package-one": patch
"@scope/package-two": patch
---

Brief summary of the change
```

## Rules

1. **ALWAYS use `patch` for bump type** - Never generate `minor` or `major` changesets
2. **Follow existing style** - Match the tone and format of existing changesets in the project
3. **Be concise** - Keep the summary brief but informative
4. **Use present tense** - Write summaries in present tense (e.g., "Fixes bug" not "Fixed bug")
5. **One changeset per logical change** - If there are multiple unrelated changes, create multiple changesets

## Example Changeset

```markdown
---
"@myapp/ui": patch
---

Fixes button hover state in dark mode

The button component now correctly displays the hover state when the application is in dark mode. Previously, the hover state was using the light theme colors.
```

## Output

- **Format:** Markdown with YAML frontmatter
- **Location:** `.changeset/`
- **Filename:** `[adjective]-[noun]-[verb].md`

## Final Instructions

1. Check if project uses changesets before generating
2. Follow the project's existing changeset pattern
3. Only use `patch` bump type
4. Generate a unique, descriptive filename
5. Keep the summary clear and concise
6. Remind user to commit the changeset file with their changes
