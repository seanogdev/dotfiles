---
name: manage-stow
description: Symlink new or changed dotfiles into $HOME with GNU Stow, and resolve stow gotchas (--adopt, .stow-local-ignore). Use when the user adds or edits a file in this repo and needs it linked into $HOME, asks why a file got moved or adopted into the repo, wants a file excluded from symlinking, or says a dotfile change "isn't showing up" — even without naming stow.
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
