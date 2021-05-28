#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

. ../scripts/functions.sh

sudo -v

info "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

info "Installing Brewfile packages..."
brew bundle --global
success "Finished installing Brewfile packages."

info "Changing default shell"

echo "/usr/local/bin/fish" | sudo tee -a /etc/shells

chsh -s `which fish`


