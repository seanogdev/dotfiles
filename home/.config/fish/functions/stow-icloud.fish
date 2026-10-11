function stow-icloud --description "Mirror iCloud dotfiles locally, then stow the mirror"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: stow-icloud"
        echo "Downloads \$ICLOUD_DOTFILES_DIR, mirrors it into \$ICLOUD_MIRROR_DIR, then stows the mirror into \$HOME."
        echo "Links each private skill from ~/.claude/skills to ~/.agents/skills, and removes broken skill links."
        echo "The mirror is left read-only. Edit files in \$ICLOUD_DOTFILES_DIR, then run stow-icloud again."
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
    chmod -R u+w $ICLOUD_MIRROR_DIR
    rsync -a --delete "$ICLOUD_DOTFILES_DIR/" "$ICLOUD_MIRROR_DIR/"

    stow -d $ICLOUD_MIRROR_DIR/fish/conf.d -t $HOME/.config/fish/conf.d --no-folding --adopt --stow .
    stow -d $ICLOUD_MIRROR_DIR -t $HOME --no-folding --adopt --stow .

    mkdir -p $HOME/.claude/skills
    for skill in $ICLOUD_MIRROR_DIR/.agents/skills/*/
        set -l name (basename $skill)
        set -l link $HOME/.claude/skills/$name
        if test -d $link; and not test -L $link
            echo "Skipping $link: it is a real directory. Remove it, then run stow-icloud again."
            continue
        end
        ln -sfn ../../.agents/skills/$name $link
    end

    find $HOME/.agents/skills $HOME/.claude/skills -type l ! -exec test -e {} \; -print -delete
    find $HOME/.agents/skills -mindepth 1 -type d -empty -delete

    chmod -R a-w $ICLOUD_MIRROR_DIR
    echo "✓ stow-icloud: mirrored $ICLOUD_DOTFILES_DIR → $ICLOUD_MIRROR_DIR, linked → $HOME"
end

