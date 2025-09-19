function tms --description "Tmux sessions"
    if not command -v fzf &>/dev/null
        echo "Error: fzf is not installed" >&2
        return 1
    end

    set -l selection (begin
        tmux list-sessions 2>/dev/null
        echo "[New Session]"
    end | fzf --height=10 --reverse)

    if test "$selection" = "[New Session]"
        tmux new-session
    else if test -n "$selection"
        set -l session (echo $selection | string split ':' | head -n1)
        tmux attach -t $session
    end
end
