set -g fish_prompt_pwd_dir_length 0
set -gx PATH $HOME/.local/bin $HOME/go/bin $PATH /usr/local/go/bin
set -gx ENHANCD_FILTER fzf
set -gx FZF_DEFAULT_OPTS "--height=~30% --layout=reverse"
if command -v podman >/dev/null 2>&1
    set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"
end

alias beautify_tsv 'csvq -i TSV -f FIXED "SELECT * FROM STDIN"'
alias cp 'cp -i'
alias egrep 'egrep --color=auto'
alias fgrep 'fgrep --color=auto'
alias gitchmod 'git update-index --add --chmod=+x'
alias gitconfig 'git config --local user.name "Shinichi Akiyama"; git config --local user.email shinichi.akiyama@gmail.com'
alias grep 'grep --color=auto'
alias less 'less -R'
alias ls 'eza -F --time-style long-iso'
alias mv 'mv -i'
alias rm 'rm -i'
alias shfmt 'shfmt -l -d -i 2 -ci -bn'
alias watch 'watch --color'

if command -v mise >/dev/null 2>&1
    mise activate fish | source
end

if command -v atuin >/dev/null 2>&1
    atuin init fish | source
end
