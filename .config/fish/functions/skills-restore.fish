function skills-restore --description "Reinstall skills from \$HOME/.Skillfile into ~/.agents/skills/ and symlink into ~/.claude/skills/"
    set -l infile $HOME/.Skillfile
    set -l agents_dir $HOME/.agents/skills
    set -l claude_dir $HOME/.claude/skills
    test -f $infile; or begin
        echo "No $infile — run skills-backup first" >&2
        return 1
    end
    mkdir -p $agents_dir $claude_dir
    for line in (cat $infile)
        test -z "$line"; and continue
        set -l parts (string split ' ' -- $line)
        gh skill install $parts[1] $parts[2] --dir $agents_dir --force </dev/null; or continue
        set -l name (basename $parts[2])
        set -l src $agents_dir/$name
        set -l dst $claude_dir/$name
        if test -L $dst
            set -l current (readlink $dst)
            if test "$current" = "$src"
                continue
            end
            echo "skip $name: ~/.claude/skills/$name is a symlink to $current (not ours)" >&2
            continue
        end
        if test -e $dst
            echo "skip $name: ~/.claude/skills/$name exists and is not a symlink" >&2
            continue
        end
        ln -s $src $dst
    end
end
