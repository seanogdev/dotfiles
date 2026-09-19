---
name: manage-stow
description: Symlink new or changed dotfiles into $HOME with GNU Stow, and resolve stow gotchas (--adopt, .stow-local-ignore). Use when the user adds or edits a file in this repo and needs it linked into $HOME, asks why a file got moved or adopted into the repo, wants a file excluded from symlinking, or says a dotfile change "isn't showing up" — even without naming stow.
license: MIT
---

After you add or modify a file, symlink the dotfiles with `stow-local` (or `stow-icloud`, `stow-all`). Each takes `--help`.

## Gotchas

- **`--adopt`**: run `git diff` after you stow and review each adopted file before you commit it.
- **`.stow-local-ignore`** lists the files this repo does not project into `$HOME`.
