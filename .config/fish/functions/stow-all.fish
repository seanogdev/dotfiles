function stow-all --description "Stow dotfiles in both local and iCloud directories"
    stow-local; or return 1
    stow-icloud; or return 1
    echo "✓ stow-all: done"
end
