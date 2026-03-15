function rename-tab --description "Rename the current Ghostty tab"
    printf '\e]2;%s\a' "$argv"
end
