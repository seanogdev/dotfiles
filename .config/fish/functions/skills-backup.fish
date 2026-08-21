function skills-backup --description "Back up installed user-scope skills to \$HOME/.Skillfile"
    set -l outfile $HOME/.Skillfile
    set -l jqexpr '.[] | select(.sourceURL != "") | .path + "\t" + (.sourceURL | ltrimstr("https://github.com/") | rtrimstr(".git"))'
    set -l rows (gh skill list --agent universal --scope user --json path,sourceURL --jq $jqexpr)
    or begin
        echo "gh skill list failed — $outfile left unchanged" >&2
        return 1
    end
    set -l lines
    for row in $rows
        set -l parts (string split \t -- $row)
        # skillName is namespaced (author/skill) and does not always resolve on
        # install, so take the exact repo path from frontmatter instead.
        set -l path (string match -rg '^\s*github-path:\s*(\S+)' < $parts[1]/SKILL.md | head -1)
        test -n "$path"; or continue
        set -a lines "$parts[2] $path"
    end
    set -l sorted (printf '%s\n' $lines | sort -u)
    # Write through the symlink: `sort -o` renames over the file, which would
    # replace the stow symlink at ~/.Skillfile with a plain file.
    if set -q sorted[1]
        printf '%s\n' $sorted >$outfile
    else
        : >$outfile
    end
    echo "Wrote "(count $sorted)" skill(s) to $outfile"
end
