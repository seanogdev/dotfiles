function icloud-push --description "Push local mirror changes back to iCloud"
    if not test -d $ICLOUD_DOTFILES_DIR
        echo "iCloud dotfiles directory does not exist."
        return 1
    end
    if not test -d $ICLOUD_MIRROR_DIR
        echo "Local iCloud mirror does not exist. Run stow-icloud first."
        return 1
    end

    rsync -a --delete "$ICLOUD_MIRROR_DIR/" "$ICLOUD_DOTFILES_DIR/"
    echo "✓ icloud-push: pushed $ICLOUD_MIRROR_DIR → $ICLOUD_DOTFILES_DIR"
end
