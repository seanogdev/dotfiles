# seanogdev/dotfiles

This is a personal dotfiles repository that uses GNU Stow for symlink management and Homebrew for package installation. The setup follows a structured approach to manage configuration files across macOS systems.

**Shell: Fish (`/opt/homebrew/bin/fish`) is the default shell. Use Fish for all commands unless noted otherwise.**

## Setup Commands

**Initial setup:**

```bash
# Install Homebrew first (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Run setup script (installs stow, links dotfiles, installs packages, installs fonts)
./setup.sh
```

**Install fonts from iCloud:**

```fish
./install-fonts.sh
```

**Update Homebrew packages:**

```fish
brew bundle install --global  # Install from .Brewfile
```

## Architecture

### iCloud Integration

- Fonts copied from `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/sync/fonts/`
- Sensitive Fish functions are mirrored from iCloud to `$ICLOUD_MIRROR_DIR` (`~/.local/share/dotfiles-icloud-mirror`, outside the iCloud container), then stowed from there. This keeps `~/.config/fish/conf.d/keys.fish` and friends symlinked to a stable local path, not a live path inside `Mobile Documents`, so macOS stops re-prompting for permission on every iCloud sync event. Edit these files in iCloud Drive, then run `stow-icloud` to pull them into the mirror.

### Skills

Two dotfiles-specific skills live at `.agents/skills/<name>/SKILL.md`: `manage-skills` and
`manage-stow`. General-purpose skills live in [seanogdev/skills](https://github.com/seanogdev/skills)
instead.

## Setup: Claude Code Status Line

The statusline script lives at `~/.claude/statusline-command.fish` (symlinked from dotfiles via stow).

## Maintenance

**Update all system tools (Homebrew, fish plugins, macOS, etc.):**

```fish
update-mac
```

## Gotchas

- **`.agents`/`AGENTS.md` is canonical for instructions, `.claude`/`CLAUDE.md` are symlinks to it**: root `CLAUDE.md -> AGENTS.md`, `.claude/CLAUDE.md -> ../.agents/AGENTS.md`. Stow projects both trees to `~/.agents/` and `~/.claude/`. Add new content under `.agents/`, then symlink it from `.claude/`.
- **The two personal skills are canonical at `.agents/skills/<name>/SKILL.md`**, the agentskills.io convention. `.claude/skills/<name>` is a symlink to `../../.agents/skills/<name>`, matching how `gh skill`-managed skills are laid out.
