# seanogdev/dotfiles

This is a personal dotfiles repository that uses GNU Stow for symlink management and Homebrew for package installation. The setup follows a structured approach to manage configuration files across macOS systems.

## Setup Commands

**Initial setup:**

```bash
# Install Homebrew first (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Run setup script (installs stow, links dotfiles, installs packages, syncs iCloud data)
./setup.sh
```

**Sync iCloud data (fonts and sensitive functions):**

```bash
./sync.sh
```

**Update Homebrew packages:**

```bash
brew bundle install --global  # Install from .Brewfile
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
```

## Development Environment

- Default shell: Fish (`/opt/homebrew/bin/fish`)
- Node.js: Managed via FNM with automatic version switching
- Package managers: npm, pnpm (with custom Starship indicators)
- Editor: VS Code with extensive extension set defined in `.Brewfile`
