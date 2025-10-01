function stow-local --description "Stow dotfiles in the local directory"
    if test -d $DOTFILES_DIR
        stow -d $DOTFILES_DIR -t $HOME --no-folding --adopt --stow .
    else
        echo "Local dotfiles directory does not exist."
    end
end
