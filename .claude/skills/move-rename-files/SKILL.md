---
name: move-rename-files
description: Efficiently move, rename, and update file references across a codebase. Use when the user wants to: (1) move files to a new directory and update all import paths, (2) rename files and fix all references, (3) bulk-restructure a directory and update deep import paths. Follows the project's existing naming conventions.
---

# Move, Rename & Update Files

## Workflow

Four phases. **Do not skip ahead or interleave phases.**

### Phase 1: Discover (batch)

1. Use Glob to sample existing filenames in the target directory to infer the project's naming convention (PascalCase, kebab-case, camelCase, etc.).
2. Use Glob to list every source file being moved/renamed.
3. For each unique filename or path segment changing, run one broad Grep across the whole project — use `output_mode: "files_with_matches"` to get every affected file at once. Do NOT grep file-by-file.
4. Result: full set of files to move + full set of files with references to update.

### Phase 2: Plan

Build a mapping table and show it to the user:

| Old path                    | New path                  |
| --------------------------- | ------------------------- |
| src/components/UserCard.vue | src/features/UserCard.vue |

For each reference file, note which strings change (import paths, tag names).
**Wait for user confirmation before proceeding.**

### Phase 3: Execute

Order is mandatory — **moves first, reference updates second.**

1. Move files with `git mv <old> <new>` (preserves history). Use `mv` only if not in a git repo.
2. Update references: for each affected file, use the Edit tool. Batch all changes to one file into a single Edit call.

### Phase 4: Verify

Grep for any remaining old paths or identifiers. Fix anything found before finishing.

## Key Rules

- Never update imports before moving files — broken intermediate state confuses editors and tools.
- One Grep per pattern, not one per file — grep broadly across the whole project.
- Match the naming convention of the destination — infer it from existing files in step 1, don't assume.
- See `references/import-patterns.md` for grep patterns by file type.
