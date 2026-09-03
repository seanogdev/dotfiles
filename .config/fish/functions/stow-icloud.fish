function stow-icloud --description "Mirror iCloud dotfiles locally, then stow the mirror"
    if not test -d $ICLOUD_DOTFILES_DIR
        echo "iCloud dotfiles directory does not exist."
        return 1
    end

    mkdir -p $ICLOUD_MIRROR_DIR
    rsync -a --delete "$ICLOUD_DOTFILES_DIR/" "$ICLOUD_MIRROR_DIR/"

    stow -d $ICLOUD_MIRROR_DIR/fish/conf.d -t $HOME/.config/fish/conf.d --no-folding --adopt --stow .
    stow -d $ICLOUD_MIRROR_DIR -t $HOME --no-folding --adopt --stow .
    echo "✓ stow-icloud: mirrored $ICLOUD_DOTFILES_DIR → $ICLOUD_MIRROR_DIR, linked → $HOME"
end

