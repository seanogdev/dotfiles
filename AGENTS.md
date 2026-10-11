# seanogdev/dotfiles

This is a personal dotfiles repository that uses GNU Stow for symlink management and Homebrew for package installation. The setup follows a structured approach to manage configuration files across macOS systems.

**Shell: Fish (`/opt/homebrew/bin/fish`) is the default shell. Use Fish for all commands unless noted otherwise.**

## Setup Commands

**Initial setup:**

```bash
# Install Homebrew first (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Run setup script (installs stow, links dotfiles, installs packages, installs fonts)
./scripts/setup.sh
```

**Install fonts from iCloud:**

```fish
./scripts/install-fonts.sh
```

**Update Homebrew packages:**

```fish
brew bundle install --global  # Install from .Brewfile
```

## Architecture

### Layout

Only `home/` is stowed. Its contents mirror `$HOME`: `home/.config/git/config` becomes `~/.config/git/config`. Everything outside `home/` stays in the repo: `scripts/` (setup and font install), `README.md`, `AGENTS.md`, `GLOSSARY.md`, `LICENSE`, `.editorconfig`. To link a new file, put it under `home/` at its `$HOME` path, then run `stow-local`.

### iCloud Integration

- Fonts copied from `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/fonts/`
- Sensitive Fish functions are mirrored from iCloud to `$ICLOUD_MIRROR_DIR` (`~/.local/share/dotfiles-icloud-mirror`, outside the iCloud container), then stowed from there. This keeps `~/.config/fish/conf.d/keys.fish` and friends symlinked to a stable local path, not a live path inside `Mobile Documents`, so macOS stops re-prompting for permission on every iCloud sync event. Edit these files in iCloud Drive, then run `stow-icloud` to pull them into the mirror.
- Private skills live in the iCloud Store at `.agents/skills/<name>/`. `stow-icloud` stows them into `~/.agents/skills/`, so every agent sees them, and links `~/.claude/skills/<name>` to `../../.agents/skills/<name>`. Edit a private skill in the iCloud Store, never through `~/.agents/skills/` or `~/.claude/skills/`: the mirror is read-only between pulls.
- `stow-icloud` waits up to 60 seconds for iCloud to download every file before it pulls, so the mirror never copies a placeholder.

### Skills

Two dotfiles-specific skills live at `home/.agents/skills/<name>/SKILL.md`: `manage-skills` and
`manage-stow`. General-purpose skills live in [seanogdev/skills](https://github.com/seanogdev/skills)
instead.

## Setup: Status Line

The `agent-statusline` fish function (`home/.config/fish/functions/agent-statusline.fish`) makes the status line for Claude Code. It takes the harness name (`claude`) as its argument.

- **Claude Code**: `~/.claude/settings.json` is not in this repo. Set `statusLine.command` to `/opt/homebrew/bin/fish -c 'agent-statusline claude'`.

## Maintenance

**Update all system tools (Homebrew, fish plugins, macOS, etc.):**

```fish
update-mac
```

## Gotchas

- **`.agents`/`AGENTS.md` is canonical for instructions, `.claude`/`CLAUDE.md` are symlinks to it**: `home/.claude/AGENTS.md -> ../.agents/AGENTS.md`. Stow projects both trees to `~/.agents/` and `~/.claude/`. Add new content under `home/.agents/`, then symlink it from `home/.claude/`.
- **The two personal skills are canonical at `home/.agents/skills/<name>/SKILL.md`**, the agentskills.io convention. `home/.claude/skills/<name>` is a symlink to `../../.agents/skills/<name>`, matching how `gh skill`-managed skills are laid out.
