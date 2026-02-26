function stow-local --description "Stow dotfiles in the local directory"
    if test -d $DOTFILES_DIR
        stow -d $DOTFILES_DIR -t $HOME --no-folding --adopt --stow .
        set broken (find $HOME -xtype l 2>/dev/null)
        if test (count $broken) -gt 0
            echo "Removing orphaned symlinks:"
            for link in $broken
                echo "  $link"
            end
            find $HOME -xtype l -delete 2>/dev/null
        end
    else
        echo "Local dotfiles directory does not exist."
    end
end
