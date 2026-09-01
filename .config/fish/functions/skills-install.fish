function skills-install --description "Install one skill into ~/.agents/skills/ and symlink it into ~/.claude/skills/"
    set -l agents_dir $HOME/.agents/skills
    set -l claude_dir $HOME/.claude/skills
    if test (count $argv) -lt 2
        echo "usage: skills-install <owner/repo> <skill-path>" >&2
        echo "skill-path is the exact repo path, as in .Skillfile" >&2
        return 1
    end
    mkdir -p $agents_dir $claude_dir
    gh skill install $argv[1] $argv[2] --dir $agents_dir --force </dev/null; or return 1
    set -l name (basename $argv[2])
    set -l src $agents_dir/$name
    set -l dst $claude_dir/$name
    if test -L $dst
        set -l current (readlink $dst)
        if test "$current" = "$src"
            echo "Installed $name"
            return 0
        end
        echo "$name installed, but ~/.claude/skills/$name points at $current (not ours) — left alone" >&2
        return 1
    end
    if test -e $dst
        echo "$name installed, but ~/.claude/skills/$name exists and is not a symlink — left alone" >&2
        return 1
    end
    ln -s $src $dst
    echo "Installed $name"
end
