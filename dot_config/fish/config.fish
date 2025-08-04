set -x PATH $HOME/.local/bin $HOME/go/bin $PATH /usr/local/go/bin
if status is-interactive
    # Commands to run in interactive sessions can go here
    set -x ENHANCD_FILTER fzf
    set -x FZF_DEFAULT_OPTS "--height=~30% --layout=reverse"

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
    alias shfmt 'shfmt -l -d -i 2 -ci -bn -kp'
    alias watch 'watch --color'
end
