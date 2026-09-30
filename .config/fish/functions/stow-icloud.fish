function stow-icloud --description "Mirror iCloud dotfiles locally, then stow the mirror"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: stow-icloud"
        echo "Downloads \$ICLOUD_DOTFILES_DIR, mirrors it into \$ICLOUD_MIRROR_DIR, then stows the mirror into \$HOME."
        return 0
    end
    if not test -d $ICLOUD_DOTFILES_DIR
        echo "iCloud dotfiles directory does not exist."
        return 1
    end

    brctl download $ICLOUD_DOTFILES_DIR
    set -l deadline (math (date +%s) + 60)
    while test -n "$(find $ICLOUD_DOTFILES_DIR -flags +dataless -print -quit)"
        if test (date +%s) -ge $deadline
            echo "iCloud has not finished downloading $ICLOUD_DOTFILES_DIR. Try again later."
            return 1
        end
        sleep 1
    end

    mkdir -p $ICLOUD_MIRROR_DIR
    rsync -a --delete "$ICLOUD_DOTFILES_DIR/" "$ICLOUD_MIRROR_DIR/"

    stow -d $ICLOUD_MIRROR_DIR/fish/conf.d -t $HOME/.config/fish/conf.d --no-folding --adopt --stow .
    stow -d $ICLOUD_MIRROR_DIR -t $HOME --no-folding --adopt --stow .
    echo "✓ stow-icloud: mirrored $ICLOUD_DOTFILES_DIR → $ICLOUD_MIRROR_DIR, linked → $HOME"
end

