#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name")
set cwd (echo $input | jq -r ".workspace.current_dir")
set tokens_used (echo $input | jq -r ".tokens_used // 0")
set token_budget (echo $input | jq -r ".token_budget // 0")

# Calculate context percentage
set context_pct 0
if test "$token_budget" -gt 0
    set context_pct (math "round($tokens_used / $token_budget * 100)" 2>/dev/null)
    or set context_pct 0
end
if test -z "$context_pct"
    set context_pct 0
end

# Get git branch info
set git_branch (git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
set git_info ""
if test -n "$git_branch"
    set git_info " "(printf "\033[1;35m󰘬 %s\033[0m" "$git_branch")
end

# Get directory name
set dir_name (basename "$cwd")

# Build right side info
set right_info ""

# Add Node.js version if available
if command -v node >/dev/null 2>&1
    set node_version (node --version 2>/dev/null)
    if test -n "$node_version"
        set right_info "$right_info "(printf "\033[1;32m◆ %s\033[0m" "$node_version")
    end
end

# Add pnpm version if available
if command -v pnpm >/dev/null 2>&1
    set pnpm_version (pnpm --version 2>/dev/null)
    if test -n "$pnpm_version"
        if test -n "$right_info"
            set right_info "$right_info "
        end
        set right_info "$right_info"(printf "\033[1;33mpnpm v%s\033[0m" "$pnpm_version")
    end
end

# Add current time
set current_time (date +%H:%M:%S)
if test -n "$right_info"
    set right_info "$right_info "
end
set right_info "$right_info"(printf "\033[2m%s\033[0m" "$current_time")

# Print the complete status line
printf "\033[1;36m%s\033[0m%s \033[1;33m[%s]\033[0m \033[1;32m[%s%%]\033[0m %s" "$dir_name" "$git_info" "$model" "$context_pct" "$right_info"
