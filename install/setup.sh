#! /usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES=$(pwd -P)

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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    brew update
fi

info "Installing Brewfile packages..."
brew bundle install --global
success "Finished installing Brewfile packages."

info "Changing default shell"

FISH_PATH="/usr/local/bin/fish"

if [[ $(uname -m) == 'arm64' ]]; then
    FISH_PATH="/opt/homebrew/bin/fish"
fi

echo $FISH_PATH | sudo tee -a /etc/shells

chsh -s "$(which fish)"

sh ./symlink.sh


