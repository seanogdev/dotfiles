function pnpm-up --description "Upgrade PNPM to latest"
    corepack enable
    corepack prepare pnpm@latest --activate
end