# ~/.bash_aliases — エイリアス定義

# ls 系(eza があれば置き換え)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la --git --icons=auto'
    alias la='eza -a'
    alias lt='eza --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
fi

# cat 系(bat があれば置き換え。Ubuntu ではコマンド名が batcat)
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never'
    alias bat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi

# fd(Ubuntu ではコマンド名が fdfind)
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'

# grep に色
alias grep='grep --color=auto'

# 移動
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# git ショートカット
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gp='git push'

# 安全側に倒す
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -I'

# docker
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# npm / node
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'

# その他
alias vi='nvim'
alias vim='nvim'
alias reload='source ~/.bashrc'
alias ports='ss -tulpn'
alias df='df -h'
alias du='du -h'
