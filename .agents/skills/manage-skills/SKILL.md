---
name: manage-skills
description: Install, update, back up, and restore Claude Code skills for this dotfiles setup via `gh skill` and the skills-install/backup/restore/update fish functions. Use when the user wants to install a new skill, update skills, back up or restore the skill inventory, or asks about .Skillfile.
---

Manage skills with `gh skill` (GitHub CLI, preview). Install each skill to the canonical location `~/.agents/skills/`, the agentskills.io convention. Claude Code reads from `~/.claude/skills/`. Each managed skill there is a symlink into `~/.agents/skills/<name>`.

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
- `gh skill` does not follow a symlinked skill directory. `address-review` is a symlink in `~/.agents/skills/`. Every scan skips it. The scan gives no warning.
- Each `.Skillfile` line is `<owner/repo> <skill-path>`. The path is the exact repo path from the `github-path` frontmatter. Do not substitute the namespaced name that `gh skill list` reports. The path `accessibility-compliance/wcag-audit-patterns` fails to install. The path `plugins/accessibility-compliance/skills/wcag-audit-patterns` works. `gh skill list --json` has no field for the exact path. Therefore `skills-backup` reads the frontmatter to get it.
- `.Skillfile` excludes every skill without `github-repo` frontmatter. The private skills below have no `github-repo` frontmatter. They never appear in `.Skillfile`.
- The private skills are `content-writer` and `review-pr`. They live in iCloud at `~/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/.claude/skills/`. Their symlinks into `~/.claude/skills/` are manual. `sync.sh` copies only fonts. To edit a private skill, edit the iCloud copy. To add a reference file to a private skill, symlink the whole `references` directory. Do not symlink each file.
- Project-scope skills belong in `.claude/skills/` in the repo. Do not commit user-scope skill artifacts there.
