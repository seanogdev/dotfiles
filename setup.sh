#! /usr/bin/env bash

cd "$(dirname "$0")/.."

set -e

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] %s\n" "$1"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s" "$1"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
  echo ''
  exit
}

info "Installing Homebrew..."

# if brew is not installed
if ! command -v brew &> /dev/null
then
    fail "Homebrew could not be found, please install it from https://brew.sh/"
fi

info "Installing stow"

brew install stow

info "Linking dotfiles with stow"

stow -d "$HOME/projects/personal/dotfiles" -t "$HOME" --no-folding --adopt .

info "Installing Brewfile packages..."

brew bundle install --global

info "Syncing iCloud data"

sh ./sync.sh

info "Changing default shell"

echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells

chsh -s "$(which fish)"



