function claude --description "Claude Code in its own scope so systemd-oomd can kill one session at a time"
    # is-system-running also fails when the manager is degraded, so probe the bus instead;
    # systemd-run execs its argv directly, so resolve the path here instead of passing the builtin "command"
    if command -q systemd-run; and systemctl --user show-environment >/dev/null 2>&1; and set -f exe (command -s claude)
        systemd-run --user --scope --quiet --description="Claude Code" -- $exe $argv
    else
        command claude $argv
    end
end
