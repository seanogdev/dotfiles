---
name: manage-skills
description: Install, update, back up, and restore GitHub-hosted Claude Code skills for this dotfiles setup — third-party skills and Sean's own seanogdev/skills alike. Use when the user wants to add a skill from a GitHub repo, keep installed skills current, back up or restore the skill inventory across machines, or asks about `gh skill`, `.Skillfile`, or the skills-install/backup/restore/update fish functions — even when they don't say "skill," e.g. "set this laptop up with my usual skills" or "is there an update for that thing I installed." Does not cover editing the two dotfiles-specific skills under `skills/<name>` in this repo (`manage-skills`, `manage-stow`).
license: MIT
---

Manage GitHub-hosted skills with `gh skill` (GitHub CLI, preview). Install each one to the canonical location `~/.agents/skills/`, the agentskills.io convention. Claude Code reads from `~/.claude/skills/`. Each managed skill there is a symlink into `~/.agents/skills/<name>`. This covers both third-party skills and Sean's own general-purpose skills in [seanogdev/skills](https://github.com/seanogdev/skills) (`address-review`, `create-pr`, `prune-merged-branches`, `quote-clip`) — they install the same way.

Two skills are different: `manage-skills` and `manage-stow` are dotfiles-specific, so they live in this repo at `skills/<name>/SKILL.md` instead. `.agents/skills/<name>` and `.claude/skills/<name>` are symlinks to `../../skills/<name>`. Stow projects those symlinks into `$HOME`. `gh skill` does not manage them.

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
- `gh skill` does not follow a symlinked skill directory. `manage-skills` and `manage-stow` are each a symlink in `~/.agents/skills/`. Every scan skips them. The scan gives no warning. This is correct here. Neither has `github-repo` frontmatter, so `gh skill` has nothing to update.
- Each `.Skillfile` line is `<owner/repo> <skill-path>`. The path is the exact repo path from the `github-path` frontmatter. Do not substitute the namespaced name that `gh skill list` reports. The path `accessibility-compliance/wcag-audit-patterns` fails to install. The path `plugins/accessibility-compliance/skills/wcag-audit-patterns` works. `gh skill list --json` has no field for the exact path. Therefore `skills-backup` reads the frontmatter to get it.
- `.Skillfile` excludes every skill without `github-repo` frontmatter. The private skills below have no `github-repo` frontmatter. They never appear in `.Skillfile`.
- The private skills are `content-writer` and `review-pr`. They live in iCloud at `~/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/.claude/skills/`. Their symlinks into `~/.claude/skills/` are manual. `sync.sh` copies only fonts. To edit a private skill, edit the iCloud copy. To add a reference file to a private skill, symlink the whole `references` directory. Do not symlink each file.
- Project-scope skills belong in `.claude/skills/` in the project repo. Do not commit user-scope skill artifacts there. The dotfiles repo is the exception. Its `.claude/skills/` holds the symlinks that stow projects into `$HOME`.
- `seanogdev/skills`, not this repo, is the Claude Code plugin root for the general-purpose skills. Its `.claude-plugin/plugin.json` declares the plugin `seanog-skills`. To add a skill to that plugin, add it under `skills/` there. There is no list to update.
