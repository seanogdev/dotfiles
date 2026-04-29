function stow-icloud --description "Stow dotfiles in the iCloud directory"
    if not test -d $ICLOUD_DOTFILES_DIR
        echo "iCloud dotfiles directory does not exist."
        return 1
    end

    stow -d $ICLOUD_DOTFILES_DIR/fish/conf.d -t $HOME/.config/fish/conf.d --no-folding --adopt --stow .
    stow -d $ICLOUD_DOTFILES_DIR -t $HOME --no-folding --adopt --stow .
    echo "✓ stow-icloud: linked $ICLOUD_DOTFILES_DIR → $HOME"
end

