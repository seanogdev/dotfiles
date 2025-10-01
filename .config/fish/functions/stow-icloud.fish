function stow-icloud --description "Stow dotfiles in the iCloud directory"
    if test -d $ICLOUD_DOTFILES_DIR
        stow -d $ICLOUD_DOTFILES_DIR/fish/conf.d -t $HOME/.config/fish/conf.d --no-folding --adopt --stow .
    else
        echo "iCloud dotfiles directory does not exist."
    end
end

