function brew-restore --description "Sync installed brews to match $HOME/.Brewfile"
    brew bundle cleanup --global --force --zap
    brew bundle install --global
end
