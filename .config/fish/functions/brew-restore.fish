function brew-restore --description "Sync installed brews to match $HOME/.Brewfile"
    brew bundle install --global
    brew bundle cleanup --global --force
end
