function brew-restore --description "Sync installed brews to match $HOME/.Brewfile"
    brew bundle install --global --force --cleanup
end
