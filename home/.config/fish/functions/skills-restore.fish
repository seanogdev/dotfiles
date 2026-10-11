function skills-restore --description "Sync ~/.agents/skills/ with \$HOME/.Skillfile and symlink into ~/.claude/skills/"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: skills-restore"
        echo "Reinstalls every skill listed in \$HOME/.Skillfile and removes gh-skill-installed skills that it does not list."
        return 0
    end
    set -l infile $HOME/.Skillfile
    set -l agents_dir $HOME/.agents/skills
    set -l claude_dir $HOME/.claude/skills
    test -f $infile; or begin
        echo "No $infile — run skills-backup first" >&2
        return 1
    end
    mkdir -p $agents_dir $claude_dir
    set -l names
    for line in (cat $infile)
        test -z "$line"; and continue
        set -l parts (string split ' ' -- $line)
        set -l name (basename $parts[2])
        set -a names $name
        set -l pin
        set -q parts[3]; and set pin --pin $parts[3]
        set -l src $agents_dir/$name
        # Install fresh, then swap it in: --force keeps files the new version no longer has.
        set -l tmp (mktemp -d)
        if not gh skill install $parts[1] $parts[2] $pin --dir $tmp </dev/null; or not test -d $tmp/$name
            rm -rf $tmp
            continue
        end
        rm -rf $src
        mv $tmp/$name $src
        rm -rf $tmp
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
    for src in $agents_dir/*
        set -l name (basename $src)
        contains -- $name $names; and continue
        test -f $src/SKILL.md; or continue
        string match -rq '^\s*github-repo:' <$src/SKILL.md; or continue
        set -l dst $claude_dir/$name
        test -L $dst; and test (readlink $dst) = $src; and rm $dst
        rm -rf $src
        echo "removed $name: not in $infile"
    end
end
