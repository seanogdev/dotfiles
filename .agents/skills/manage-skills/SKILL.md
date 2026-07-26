---
name: manage-skills
description: Install, update, back up, and restore Claude Code skills for this dotfiles setup via `gh skill` and the skills-backup/restore/update fish functions. Use when the user wants to install a new skill, update skills, back up or restore the skill inventory, or asks about .Skillfile.
---

Skills are managed via `gh skill` (GitHub CLI, preview). The canonical install location is `~/.agents/skills/` (the agentskills.io convention). Claude Code reads from `~/.claude/skills/`, where each gh-managed skill is a symlink into `~/.agents/skills/<name>`. Project-scope skills (shared with the repo) live in `.claude/skills/`. Do not commit user-scope skill artifacts here.

```fish
# install to the canonical location (use --dir since no --agent maps there at user scope)
gh skill install <owner/repo> <skill-path> --dir $HOME/.agents/skills --force

# then symlink for Claude Code discovery
ln -s $HOME/.agents/skills/<name> $HOME/.claude/skills/<name>

# update all skills in the canonical dir
gh skill update --all --dir $HOME/.agents/skills

# search
gh skill search <query>
```

`gh skill` does not maintain a lock file — it only injects source-tracking metadata into each `SKILL.md` frontmatter. `gh skill update` relies on that plus `--dir` to find skills outside the default host dirs.

iCloud-synced private skills (`content-writer`, `review-pr`) are symlinked into `~/.claude/skills/` by `sync.sh`. There are currently no project-scope skills committed in `.claude/skills/` in this repo.

**Backup / restore** (mirrors `brew-backup` / `brew-restore`):

```fish
skills-backup   # scans ~/.agents/skills/, dumps to .Skillfile (committed, stow-linked to ~/.Skillfile)
skills-restore  # installs each line to ~/.agents/skills/ via --dir, then symlinks into ~/.claude/skills/
skills-update   # runs `gh skill update --all` against ~/.agents/skills/ (forwards extra args)
```

`.Skillfile` lines are `<owner/repo> <skill-path>`. iCloud and project-scope skills are intentionally excluded (no `github-repo` frontmatter).
