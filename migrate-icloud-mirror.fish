#!/usr/bin/env fish
# One-time migration: relink dotfiles that still point into the live
# iCloud path (Mobile Documents) so stow-icloud can re-link them through
# the local mirror instead. Run once per machine after `git pull`.
# Delete this file once every machine has run it.

cd (dirname (status --current-filename))

echo "Pulling latest dotfiles..."
git pull origin main

echo "Linking local files (including icloud-push)..."
stow-local

echo "Finding symlinks that still point into Mobile Documents..."
set -l stale
for f in (find $HOME -xtype l 2>/dev/null)
    if string match -q "*Mobile Documents*" (readlink $f)
        set -a stale $f
    end
end

if test (count $stale) -eq 0
    echo "No stale iCloud symlinks found."
else
    echo "Found "(count $stale)" stale symlink(s):"
    for f in $stale
        echo "  $f -> "(readlink $f)
    end
    echo ""
    read -l -P "Remove these and re-link via stow-icloud? [y/N] " confirm
    if test "$confirm" = "y" -o "$confirm" = "Y"
        rm $stale
        stow-icloud
        echo "Done."
    else
        echo "Aborted. No changes made."
    end
end
