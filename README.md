# Dotfiles

This is my personal dotfiles repository. It contains my configuration files for various programs and tools. I use this repository to keep my dotfiles in sync across multiple machines.

Main tools used:

- Brew
- Git
- Fish / Fisher
- FNM
- Starship

## Installation

```sh
git clone https://github.com/seanogdev/dotfiles.git
cd dotfiles
sh _scripts/install.sh
```

## Sync

First install Brew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install [stow](https://www.gnu.org/software/stow/):

```sh
brew install stow
```

Then link the dotfiles to your home directory:

```sh
stow --target $HOME --dir ~/dotfiles --no-folding . --adopt
```
