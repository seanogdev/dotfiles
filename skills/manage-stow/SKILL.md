---
name: manage-stow
description: Re-symlink this dotfiles repo into $HOME with GNU Stow after adding or modifying files, and handle stow gotchas (--adopt, .stow-local-ignore). Use when the user adds or edits a dotfile and needs it linked into $HOME, or asks why a file was moved/adopted into the repo, or wants to exclude a file from symlinking.
license: MIT
---

**After you add or modify a file, symlink the dotfiles:**

```fish
stow-local

# Or directly with stow
stow -d $HOME/projects/personal/dotfiles -t $HOME --no-folding --adopt --stow .
```

## Gotchas

- **`--adopt` flag**: Stow moves each conflicting file from `$HOME` into the dotfiles repo. Run `git diff` after you stow. Review each adopted file before you commit it.
- **`.stow-local-ignore`**: Stow does not symlink the files that this file lists. Examples: `CLAUDE.md`, `AGENTS.md`, `.git`.
