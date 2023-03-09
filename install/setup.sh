#! /usr/bin/env sh

DIR=$(dirname "$0")
cd "$DIR"

sudo -v

info "Installing Homebrew..."
if [[ $(command -v brew) == "" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    brew update
fi

info "Installing Brewfile packages..."
brew bundle install --global
success "Finished installing Brewfile packages."

info "Changing default shell"

FISH_PATH="/usr/local/bin/fish"

if [[ `uname -m` == 'arm64' ]]; then
    FISH_PATH="/opt/homebrew/bin/fish"
fi

echo $FISH_PATH | sudo tee -a /etc/shells

chsh -s `which fish`

sh ./symlink.sh


