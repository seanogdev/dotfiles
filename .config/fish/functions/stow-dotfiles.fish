function stow-dotfiles
    stow -d $DOTFILES_DIR -t $HOME $argv
end
