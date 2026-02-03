#!/opt/homebrew/bin/fish

# Read JSON input from stdin
set input (cat)

# Extract values from JSON
set model (echo $input | jq -r ".model.display_name")
set cwd (echo $input | jq -r ".workspace.current_dir")

# Get daily cost from ccusage
set today_date (date +%Y%m%d)
set ccusage_output (npx ccusage@latest daily --json --offline --since $today_date 2>/dev/null)

# Validate we got data for today specifically
set daily_date (echo $ccusage_output | jq -r '.daily[0].date // ""')
set cost (echo $ccusage_output | jq -r '.totals.totalCost // 0')

# Check if the date matches today and cost is reasonable (< $500/day)
if test -z "$cost"; or test "$cost" = "null"; or test "$daily_date" != (date +%Y-%m-%d)
    set cost 0
else if test (echo "$cost > 500" | bc -l) -eq 1
    # If cost seems unreasonably high for a single day, show N/A
    set cost "N/A"
end

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

# Segment 2: model name
set segment2 (printf "\033[38;5;208m%s\033[0m" "$model")

# Segment 3: cost in RAG colors
# Determine cost color based on thresholds:
# Green: $0.00 - $4.99
# Amber: $5.00 - $39.99
# Red: $40.00+
set cost_color ""
if test "$cost" = "N/A"
    set cost_color "\033[1;31m"  # Red for N/A (error state)
    set cost_display "N/A"
else
    set cost_display (printf "%.2f" $cost)
    if test (echo "$cost < 5.00" | bc -l) -eq 1
        set cost_color "\033[1;32m"  # Green
    else if test (echo "$cost < 40.00" | bc -l) -eq 1
        set cost_color "\033[1;33m"  # Amber/Yellow
    else
        set cost_color "\033[1;31m"  # Red
    end
end

set segment3 (printf "%b\$%s\033[0m" "$cost_color" "$cost_display")

# Yellow color for pipe separators
set pipe_separator (printf "\033[1;33m | \033[0m")

# Build the complete status line with pipe separators
set output "$segment1$pipe_separator$segment2$pipe_separator$segment3"

# Print the status line
printf "%s" "$output"
