function skills-update --description "Update the skills listed in ~/.Skillfile"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: skills-update [extra gh skill update flags]"
        echo "Updates each skill in \$HOME/.Skillfile, in ~/.agents/skills/. Extra args are forwarded to gh skill update."
        return 0
    end
    set -l agents_dir $HOME/.agents/skills
    set -l infile $HOME/.Skillfile
    test -d $agents_dir; or begin
        echo "No skills dir at $agents_dir" >&2
        return 1
    end
    test -f $infile; or begin
        echo "No $infile. Run skills-backup first." >&2
        return 1
    end
    set -l names
    for line in (cat $infile)
        test -z "$line"; and continue
        set -l parts (string split ' ' -- $line)
        set -a names (basename $parts[2])
    end
    gh skill update --all --dir $agents_dir $argv $names
end
