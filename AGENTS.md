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

**Symlink dotfiles after adding/modifying files:**

```fish
stow-local

# Or directly with stow
stow -d $HOME/projects/personal/dotfiles -t $HOME --no-folding --adopt --stow .
```

## Architecture

### Package Management

- **Homebrew**: Primary package manager via `.Brewfile`
  - Includes CLI tools, applications (casks), Mac App Store apps (mas), and VS Code extensions
  - Global installation using `brew bundle install --global`

### Configuration Structure

- **Stow**: Manages symlinks from dotfiles to home directory
  - Uses `--no-folding --adopt` flags for precise control
  - Target directory: `$HOME`
  - Source directory: `$HOME/projects/personal/dotfiles`

### Shell Environment

- **Fish Shell**: Primary shell with configuration in `.config/fish/`
  - Auto-loaded configurations in `conf.d/` directory
  - Custom functions in `functions/` directory
  - Completions in `completions/` directory

### Key Components

- **FNM**: Node.js version manager with corepack support
- **Starship**: Cross-shell prompt with custom configuration
- **Zoxide**: Smart directory navigation
- **GitHub CLI**: Git operations and repository management

### iCloud Integration

- Fonts synced from `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/sync/fonts/`
- Sensitive Fish functions linked from iCloud to maintain privacy

### File Organization

```
.config/
├── fish/           # Fish shell configuration
│   ├── conf.d/     # Auto-loaded configurations
│   ├── functions/  # Custom shell functions
│   └── completions/# Shell completions
├── starship.toml   # Prompt configuration
└── gh/             # GitHub CLI configuration

.claude/
├── agents/             # MCP agent configs
├── commands/           # Custom slash commands
├── skills/             # Installable Claude Code skills
├── CLAUDE.md           # Claude behavior instructions (stow-managed → ~/.claude/CLAUDE.md)
└── settings.local.json # Local Claude settings (gitignored)
```

## Setup: Claude Code Status Line

The statusline script lives at `~/.claude/statusline-command.fish` (symlinked from dotfiles via stow).

## Maintenance

**Update all system tools (Homebrew, fish plugins, macOS, etc.):**

```fish
update-mac
```

## Ghostty

- **Terminal**: Ghostty is the primary terminal emulator. Config lives at `.config/ghostty/config`.
- **Docs**: Always verify config options against https://ghostty.org/docs/config/reference before adding them — Ghostty does not warn on unknown fields.

## Skills

Skills are managed via `gh skill` (GitHub CLI, preview). User-scope skills live at `~/.claude/skills/` (not in this repo). Project-scope skills (shared with the repo) live in `.claude/skills/`. Do not commit user-scope skill artifacts here.

```fish
# install remote skill at user scope (default agent: claude-code)
gh skill install <owner/repo> <skill-name> --agent claude-code --scope user

# install from a large repo by exact path (faster, skips discovery)
gh skill install anthropics/claude-plugins-official plugins/skill-creator/skills/skill-creator --agent claude-code --scope user

# list / update / search
gh skill list # (via ls ~/.claude/skills)
gh skill update --all
gh skill search <query>
```

Project skills currently live in `.claude/skills/`: `generate-changeset`, `generate-pull-request`. iCloud-synced private skills (`content-writer`, `review-pr`) are symlinked into `~/.claude/skills/` by `sync.sh`.


## Gotchas

- **`--adopt` flag**: Stow moves conflicting files from `$HOME` into the dotfiles repo. Run `git diff` after stowing to review any adopted files before committing.
- **`.stow-local-ignore`**: Lists files excluded from symlinking (e.g., `CLAUDE.md`, `AGENTS.md`, `.git`). Edit to prevent specific files from being linked.
- **`CLAUDE.md` is a symlink**: Points to `AGENTS.md` so both Claude Code and generic agent tools share the same context.
