# Dotfiles

This is my personal dotfiles repository. It contains my configuration files for various programs and tools. I use this repository to keep my dotfiles in sync across multiple machines.

Main tools used:

- Brew
- Git
- Fish / Fisher
- FNM
- Starship

## Setting up a new machine

The repo has to live at `~/projects/personal/dotfiles`. Both `setup.sh` and
`.config/fish/conf.d/stow.fish` hardcode that path.

Install Homebrew first:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Clone over HTTPS, not SSH. The `insteadOf` rule in `.gitconfig` rewrites HTTPS to SSH, but that
config is not linked into `$HOME` until stow has run:

```sh
mkdir -p ~/projects/personal
git clone https://github.com/seanogdev/dotfiles.git ~/projects/personal/dotfiles
cd ~/projects/personal/dotfiles
./setup.sh
```

`setup.sh` installs stow, symlinks the repo into `$HOME`, installs the `.Brewfile` packages, copies
the iCloud fonts, and sets fish as the default shell.

Two things are not in the repo and need doing by hand afterwards:

- The private skills in `~/.claude/skills/` (`content-writer`, `review-pr`) live in iCloud at
  `~/Library/Mobile Documents/com~apple~CloudDocs/Code/dotfiles/.claude/skills/`. Symlink them.
- The managed skills from `.Skillfile`. Run `skills-restore`.

## Pulling changes onto a machine that already has the repo

```fish
cd ~/projects/personal/dotfiles
git pull
stow-local   # only needed when files were added or renamed
```

If `git pull` reports diverged histories, the remote history was rewritten. Nothing is wrong with
your clone; it is holding commits that no longer exist. Check for local work you have not pushed,
then take the remote copy:

```fish
git stash list; git status        # check first
git fetch origin
git reset --hard origin/main
stow-local
```

The files in `$HOME` are symlinks into this repo, so a reset changes them in place. No relinking is
needed unless paths moved.
