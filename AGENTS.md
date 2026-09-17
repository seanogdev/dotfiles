# seanogdev/dotfiles

This is a personal dotfiles repository that uses GNU Stow for symlink management and Homebrew for package installation. The setup follows a structured approach to manage configuration files across macOS systems.

**Shell: Fish (`/opt/homebrew/bin/fish`) is the default shell. Use Fish for all commands unless noted otherwise.**

## Setup Commands

**Initial setup:**

```bash
# Install Homebrew first (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Run setup script (installs stow, links dotfiles, installs packages, syncs iCloud data)
./setup.sh
```

**Sync iCloud data (fonts and sensitive functions):**

```fish
./sync.sh
```

**Update Homebrew packages:**

```fish
brew bundle install --global  # Install from .Brewfile
```

## Architecture

### iCloud Integration

- Fonts synced from `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/sync/fonts/`
- Sensitive Fish functions are mirrored from iCloud to `$ICLOUD_MIRROR_DIR` (`~/.local/share/dotfiles-icloud-mirror`, outside the iCloud container), then stowed from there. `stow-icloud` pulls iCloud into the mirror; `icloud-push` pushes local mirror edits back to iCloud for other machines. This keeps `~/.config/fish/conf.d/keys.fish` and friends symlinked to a stable local path, not a live path inside `Mobile Documents`, so macOS stops re-prompting for permission on every iCloud sync event.

### Skills and the plugin

The personal skills live at `skills/<name>/SKILL.md` in the repo root. This is the layout that Claude Code plugins, `gh skill` and the Vercel skills packages all read.

The repo root is also the plugin root. `.claude-plugin/plugin.json` declares the plugin `seanog-skills`. `.claude-plugin/marketplace.json` makes the repo its own marketplace. Install the set on another machine:

```
/plugin marketplace add seanogdev/dotfiles
/plugin install seanog-skills@seanogdev
```

On this machine the skills load through stow and the symlinks, not through the plugin. Do not install the plugin here. It would give every skill twice.

## Setup: Claude Code Status Line

The statusline script lives at `~/.claude/statusline-command.fish` (symlinked from dotfiles via stow).

## Maintenance

**Update all system tools (Homebrew, fish plugins, macOS, etc.):**

```fish
update-mac
```

## Gotchas

- **`.agents`/`AGENTS.md` is canonical for instructions, `.claude`/`CLAUDE.md` are symlinks to it**: root `CLAUDE.md -> AGENTS.md`, `.claude/CLAUDE.md -> ../.agents/AGENTS.md`. Stow projects both trees to `~/.agents/` and `~/.claude/`. Add new content under `.agents/`, then symlink it from `.claude/`.
- **Skills are canonical at the repo root**: `skills/<name>/SKILL.md`. Both `.agents/skills/<name>` and `.claude/skills/<name>` are symlinks to `../../skills/<name>`, one hop each. Add a new skill under `skills/`, then symlink it from both trees.
- **Stow does not project `skills/` or `.claude-plugin/`**. Both are repo layout for the plugin. Neither belongs in `$HOME`. `.stow-local-ignore` excludes them. The skills still reach `~/.claude/skills/` through the symlinks in `.claude/skills/`.
