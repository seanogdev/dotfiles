---
name: manage-skills
description: Install, update, back up, and restore Claude Code skills for this dotfiles setup via `gh skill` and the skills-backup/restore/update fish functions. Use when the user wants to install a new skill, update skills, back up or restore the skill inventory, or asks about .Skillfile.
---

Skills are managed with `gh skill` (GitHub CLI, preview). The canonical install location is `~/.agents/skills/` (the agentskills.io convention), and Claude Code reads from `~/.claude/skills/`, where each managed skill is a symlink into `~/.agents/skills/<name>`.

```fish
# install to the canonical location (--dir, since no --agent maps there at user scope)
gh skill install <owner/repo> <skill-path> --dir $HOME/.agents/skills --force

# then symlink for Claude Code discovery
ln -s $HOME/.agents/skills/<name> $HOME/.claude/skills/<name>

gh skill update --all --dir $HOME/.agents/skills
gh skill search <query>
```

**Backup and restore** mirror `brew-backup` / `brew-restore`:

```fish
skills-backup   # scans ~/.agents/skills/, dumps to .Skillfile (committed, stow-linked to ~/.Skillfile)
skills-restore  # installs each line via --dir, then symlinks into ~/.claude/skills/
skills-update   # gh skill update --all against ~/.agents/skills/ (forwards extra args)
```

## Gotchas

- `gh skill` keeps no lock file. It injects source-tracking metadata into each `SKILL.md` frontmatter, and `gh skill update` needs that plus `--dir` to find skills outside the default host dirs.
- `.Skillfile` lines are `<owner/repo> <skill-path>`. Anything without `github-repo` frontmatter is excluded, which is why the private skills below never appear there.
- The private skills (`content-writer`, `review-pr`) live in iCloud at `~/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/.claude/skills/`. Their symlinks into `~/.claude/skills/` were made by hand, `sync.sh` only copies fonts. Editing them means editing the iCloud copy, and adding a new reference file to one means symlinking the whole `references` directory rather than each file.
- Project-scope skills would live in `.claude/skills/` in the repo. There are none right now. Do not commit user-scope skill artifacts there.
