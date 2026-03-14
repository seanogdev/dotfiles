#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name" | string replace " (1M context)" " 1M")
set cwd (echo $input | jq -r ".workspace.current_dir")
set tokens_used (echo $input | jq -r '((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0))')
set context_size (echo $input | jq -r '.context_window.context_window_size // 200000')
set used_pct (echo $input | jq -r '.context_window.used_percentage // 0')

# Get directory name
set dir_name (basename "$cwd")

# Get git branch info
set git_branch (git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
set git_info ""
if test -n "$git_branch"
    set git_info " "(printf "\033[1;35m󰘬 %s\033[0m" "$git_branch")
end

# Segment 1: directory name and git branch
set segment1 (printf "\033[1;36m%s\033[0m%s" "$dir_name" "$git_info")

# Segment 2: model name, color coded by model family
if string match -qi "*haiku*" "$model"
    set model_color "\033[38;5;111m"  # Serene periwinkle blue
else if string match -qi "*sonnet*" "$model"
    set model_color "\033[38;5;75m"   # Blue
else if string match -qi "*opus*" "$model"
    set model_color "\033[38;5;167m"  # Red
else
    set model_color "\033[38;5;208m"  # Fallback orange
end
set segment2 (printf "\033[38;5;208m✻\033[0m %b%s\033[0m" "$model_color" "$model")

# Segment 3 & 4: token count and progress bar
# Determine color based on usage percentage
if test (echo "$used_pct < 50" | bc -l) -eq 1
    set token_color "\033[1;32m"  # Green
else if test (echo "$used_pct < 80" | bc -l) -eq 1
    set token_color "\033[1;33m"  # Amber
else
    set token_color "\033[1;31m"  # Red
end

set pct_display (math --scale=0 "$used_pct")

# Format token counts: show as M if >= 1000K, otherwise K
if test $tokens_used -ge 1000000
    set tokens_fmt (math --scale=1 "$tokens_used / 1000000")"M"
else
    set tokens_fmt (math --scale=1 "$tokens_used / 1000")"k"
end
if test $context_size -ge 1000000
    set size_fmt (math --scale=0 "$context_size / 1000000")"M"
else
    set size_fmt (math --scale=0 "$context_size / 1000")"k"
end

set segment3 (printf "%b󰆼 %s/%s [%s%%]\033[0m" "$token_color" "$tokens_fmt" "$size_fmt" "$pct_display")

# Fixed-width progress bar
set bar_width 16
set filled (math --scale=0 "$bar_width * $used_pct / 100")
if test $filled -gt $bar_width
    set filled $bar_width
end
set empty (math "$bar_width - $filled")
set filled_str (string repeat -n $filled "█")
set empty_str (string repeat -n $empty "░")
set segment4 (printf "%b%s%s\033[0m" "$token_color" "$filled_str" "$empty_str")

# Yellow color for pipe separators
set pipe_separator (printf " \033[38;5;242m•\033[0m ")

# Build the complete status line with pipe separators
set output "$segment1$pipe_separator$segment2$pipe_separator$segment4 $segment3"

# Print the status line
printf "%s" "$output"
