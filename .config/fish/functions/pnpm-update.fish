function pnpm-update --description "Upgrade PNPM to latest"
    set -l c_cyan (set_color cyan);
    set -l c_normal (set_color normal);
    set -l c_yellow (set_color yellow);
    printf "%sCurrent PNPM version: %s%s%s\n" $c_cyan $c_yellow (pnpm --version) $c_normal;
    corepack enable;
    corepack prepare pnpm@latest --activate;
    printf "%sNew PNPM version: %s%s%s\n" $c_cyan $c_yellow (pnpm --version) $c_normal;
end