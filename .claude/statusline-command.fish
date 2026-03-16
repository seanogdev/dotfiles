#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name" | string replace " (1M context)" " 1M")
set cwd (echo $input | jq -r ".workspace.current_dir")
set tokens_used (echo $input | jq -r '((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0))')
set context_size (echo $input | jq -r '.context_window.context_window_size // 200000')
set optimal_limit 200000
set used_pct_of_optimal (echo "$tokens_used $optimal_limit" | awk '{printf "%.2f", ($1 / $2) * 100}')
set used_pct_of_total (echo "$tokens_used $context_size" | awk '{printf "%.2f", ($1 / $2) * 100}')

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
# Color based on usage relative to the 200K optimal limit
if test (echo "$used_pct_of_optimal < 50" | bc -l) -eq 1
    set token_color "\033[1;32m"  # Green
else if test (echo "$used_pct_of_optimal < 80" | bc -l) -eq 1
    set token_color "\033[1;33m"  # Amber
else
    set token_color "\033[1;31m"  # Red
end

set pct_display (math --scale=0 "$used_pct_of_optimal")

# Format token counts: show as M if >= 1000K, otherwise K
if test $tokens_used -ge 1000000
    set tokens_fmt (math --scale=1 "$tokens_used / 1000000")"M"
else
    set tokens_fmt (math --scale=1 "$tokens_used / 1000")"k"
end
set optimal_fmt (math --scale=0 "$optimal_limit / 1000")"k"
if test $context_size -ge 1000000
    set size_fmt (math --scale=0 "$context_size / 1000000")"M"
else
    set size_fmt (math --scale=0 "$context_size / 1000")"k"
end

set segment3 (printf "%b󰆼 %s/%s [%s%%]\033[0m" "$token_color" "$tokens_fmt" "$size_fmt" "$pct_display")

# Progress bar: two zones — optimal (0-200K) gets 14 chars, overflow (200K-1M) gets 6 chars
set optimal_width 14
set overflow_width 6
set bar_width (math "$optimal_width + $overflow_width")

# How many chars are filled in each zone
if test (echo "$tokens_used <= $optimal_limit" | bc -l) -eq 1
    # Usage within optimal zone
    set optimal_filled (math --scale=0 "$optimal_width * $tokens_used / $optimal_limit")
    set overflow_filled 0
else
    # Usage spills into overflow zone
    set optimal_filled $optimal_width
    set overflow_tokens (math "$tokens_used - $optimal_limit")
    set overflow_total (math "$context_size - $optimal_limit")
    set overflow_filled (math --scale=0 "$overflow_width * $overflow_tokens / $overflow_total")
    if test $overflow_filled -gt $overflow_width
        set overflow_filled $overflow_width
    end
end

# Build the bar in a single printf to avoid fish variable concatenation gaps
set opt_empty (math "$optimal_width - $optimal_filled")
set ovf_empty (math "$overflow_width - $overflow_filled")

set opt_filled_chars (string repeat -n $optimal_filled "█")
set opt_empty_chars (string repeat -n $opt_empty "░")
set ovf_filled_chars (string repeat -n $overflow_filled "█")
set ovf_empty_chars (string repeat -n $ovf_empty "░")

set segment4 (printf "%b%s\033[38;5;242m%s│\033[0m%b%s\033[38;5;237m%s\033[0m" "$token_color" "$opt_filled_chars" "$opt_empty_chars" "$token_color" "$ovf_filled_chars" "$ovf_empty_chars")

# Yellow color for pipe separators
set pipe_separator (printf " \033[38;5;242m•\033[0m ")

# Build the complete status line with pipe separators
set output "$segment1$pipe_separator$segment2$pipe_separator$segment4 $segment3"

# Print the status line
printf "%s" "$output"
