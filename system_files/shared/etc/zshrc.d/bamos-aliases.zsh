# BamOS Zsh Configuration (inspired by RakuOS)
# Source: /etc/zshrc.d/bamos-aliases.zsh

# bamos CLI shortcuts
alias bamos-install='bamos install'
alias bamos-remove='bamos remove'
alias bamos-update='bamos update'
alias bamos-upgrade='bamos upgrade'
alias bamos-list='bamos list'
alias bamos-search='bamos search'

# Common package management shortcuts
alias install='echo "Use: bamos install <package>"'
alias update='bamos update'
alias upgrade='bamos upgrade'

# System info
alias sysinfo='fastfetch'
alias neofetch='fastfetch'

# Navigation shortcuts
alias ll='lsd -la'
alias la='lsd -a'
alias l='lsd -l'
alias tree='lsd --tree'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'

# Docker/Podman
alias docker='podman'
alias docker-compose='podman-compose'
