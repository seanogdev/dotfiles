function skills-restore --description "Reinstall skills from \$HOME/.Skillfile (claude-code user scope)"
    set -l infile $HOME/.Skillfile
    test -f $infile; or begin
        echo "No $infile — run skills-backup first" >&2
        return 1
    end
    for line in (cat $infile)
        test -z "$line"; and continue
        set -l parts (string split ' ' -- $line)
        gh skill install $parts[1] $parts[2] --agent claude-code --scope user --force
    end
end
