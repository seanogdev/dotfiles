function skills-update --description "Update all skills installed in ~/.agents/skills/"
    if contains -- -h $argv; or contains -- --help $argv
        echo "usage: skills-update [extra gh skill update flags]"
        echo "Updates every skill in ~/.agents/skills/. Extra args are forwarded to gh skill update."
        return 0
    end
    set -l agents_dir $HOME/.agents/skills
    test -d $agents_dir; or begin
        echo "No skills dir at $agents_dir" >&2
        return 1
    end
    gh skill update --all --dir $agents_dir $argv
end
