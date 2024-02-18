function brew-backup --description "Backup your brews to $HOME/.Brewfile"
    brew bundle dump --global --force
end
