function skills-backup --description "Back up installed user-scope skills to \$HOME/.Skillfile"
    set -l skills_dir $HOME/.agents/skills
    set -l outfile $HOME/.Skillfile
    test -d $skills_dir; or begin
        echo "No skills dir at $skills_dir" >&2
        return 1
    end
    : > $outfile
    for dir in $skills_dir/*/
        set -l skillmd $dir"SKILL.md"
        test -f $skillmd; or continue
        set -l repo (grep -E '^\s*github-repo:' $skillmd | head -1 | string replace -r '^\s*github-repo:\s*' '' | string trim)
        set -l path (grep -E '^\s*github-path:' $skillmd | head -1 | string replace -r '^\s*github-path:\s*' '' | string trim)
        test -n "$repo" -a -n "$path"; or continue
        set repo (string replace -r '^https?://github.com/' '' -- $repo | string replace -r '\.git$' '')
        echo "$repo $path" >> $outfile
    end
    # Sort in place *through* the symlink: `sort -o` renames over the file,
    # which would replace the stow symlink at ~/.Skillfile with a plain file.
    set -l sorted (sort -u $outfile)
    if set -q sorted[1]
        printf '%s\n' $sorted >$outfile
    else
        : >$outfile
    end
    echo "Wrote "(wc -l < $outfile | string trim)" skill(s) to $outfile"
end
