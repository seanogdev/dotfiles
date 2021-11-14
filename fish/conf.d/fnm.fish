if type fnm && status is-interactive
    fnm env --shell fish --use-on-cd | source
    fnm completions --shell fish | source
end
