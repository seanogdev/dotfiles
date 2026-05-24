function skills-update --description "Update all skills installed in ~/.agents/skills/"
    set -l agents_dir $HOME/.agents/skills
    test -d $agents_dir; or begin
        echo "No skills dir at $agents_dir" >&2
        return 1
    end
    gh skill update --all --dir $agents_dir $argv
end
