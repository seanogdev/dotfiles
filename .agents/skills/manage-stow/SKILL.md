---
name: manage-stow
description: Re-symlink this dotfiles repo into $HOME with GNU Stow after adding or modifying files, and handle stow gotchas (--adopt, .stow-local-ignore). Use when the user adds or edits a dotfile and needs it linked into $HOME, or asks why a file was moved/adopted into the repo, or wants to exclude a file from symlinking.
---

**Symlink dotfiles after adding/modifying files:**

```fish
stow-local

# Or directly with stow
stow -d $HOME/projects/personal/dotfiles -t $HOME --no-folding --adopt --stow .
```

## Gotchas

- **`--adopt` flag**: Stow moves conflicting files from `$HOME` into the dotfiles repo. Run `git diff` after stowing to review any adopted files before committing.
- **`.stow-local-ignore`**: Lists files excluded from symlinking (e.g., `CLAUDE.md`, `AGENTS.md`, `.git`). Edit to prevent specific files from being linked.
