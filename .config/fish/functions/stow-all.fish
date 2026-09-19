function stow-all --description "Stow dotfiles in both local and iCloud directories"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: stow-all"
        echo "Runs stow-local then stow-icloud."
        return 0
    end
    stow-local; or return 1
    stow-icloud; or return 1
    echo "✓ stow-all: done"
end
