---
name: manage-skills
description: Install, update, back up, and restore third-party Claude Code skills for this dotfiles setup. Use when the user wants to add a skill from a GitHub repo, keep installed skills current, back up or restore the skill inventory across machines, or asks about `gh skill`, `.Skillfile`, or the skills-install/backup/restore/update fish functions — even when they don't say "skill," e.g. "set this laptop up with my usual skills" or "is there an update for that thing I installed." Does not cover editing the personal skills under `skills/<name>` in this repo.
license: MIT
---

Manage third-party skills with `gh skill` (GitHub CLI, preview). Install each one to the canonical location `~/.agents/skills/`, the agentskills.io convention. Claude Code reads from `~/.claude/skills/`. Each managed skill there is a symlink into `~/.agents/skills/<name>`.

The personal skills are different. They live in the dotfiles repo at `skills/<name>/SKILL.md`. `.agents/skills/<name>` and `.claude/skills/<name>` are symlinks to `../../skills/<name>`. Stow projects those symlinks into `$HOME`. `gh skill` does not manage them.

```fish
skills-install <owner/repo> <skill-path>
gh skill search <query>
```

**Backup and restore** follow the same pattern as `brew-backup` / `brew-restore`:

```fish
skills-backup   # gh skill list --json, dumps to .Skillfile (committed, stow-linked to ~/.Skillfile)
skills-restore  # installs each line via --dir, then symlinks into ~/.claude/skills/
skills-update   # gh skill update --all against ~/.agents/skills/ (forwards extra args)
```

## Gotchas

- `gh skill` keeps no lock file. It reads no manifest. It writes source-tracking metadata into the frontmatter of each `SKILL.md`. `gh skill update` needs that metadata to detect a change.
- Scope `gh skill update` with `--dir`. Unscoped, it scans every agent host on the machine. These hosts include `~/.config/goose/skills/` and `~/.config/opencode/skills/`. The scan buries the real output in warnings.
- `gh skill` does not follow a symlinked skill directory. Every personal skill is a symlink in `~/.agents/skills/`. Every scan skips all of them. The scan gives no warning. This is correct here. Each personal skill has no `github-repo` frontmatter, so `gh skill` has nothing to update.
- Each `.Skillfile` line is `<owner/repo> <skill-path>`. The path is the exact repo path from the `github-path` frontmatter. Do not substitute the namespaced name that `gh skill list` reports. The path `accessibility-compliance/wcag-audit-patterns` fails to install. The path `plugins/accessibility-compliance/skills/wcag-audit-patterns` works. `gh skill list --json` has no field for the exact path. Therefore `skills-backup` reads the frontmatter to get it.
- `.Skillfile` excludes every skill without `github-repo` frontmatter. The private skills below have no `github-repo` frontmatter. They never appear in `.Skillfile`.
- The private skills are `content-writer` and `review-pr`. They live in iCloud at `~/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/.claude/skills/`. Their symlinks into `~/.claude/skills/` are manual. `sync.sh` copies only fonts. To edit a private skill, edit the iCloud copy. To add a reference file to a private skill, symlink the whole `references` directory. Do not symlink each file.
- Project-scope skills belong in `.claude/skills/` in the project repo. Do not commit user-scope skill artifacts there. The dotfiles repo is the exception. Its `.claude/skills/` holds the symlinks that stow projects into `$HOME`.
- The dotfiles repo root is also a Claude Code plugin root. `.claude-plugin/plugin.json` declares the plugin `seanog-skills`. It publishes the same `skills/` directory. To add a skill to the plugin, add it under `skills/`. There is no list to update.
