# BamOS Fish Shell Configuration
# Adapted from RakuOS fish aliases
# Vietnamese-friendly shell experience with modern defaults

# ── BamOS aliases ────────────────────────────────────────────────────────────

# Package management shortcuts
abbr -a bai  'bamos install'
abbr -a bar  'bamos remove'
abbr -a bau  'bamos update'
abbr -a baug 'bamos upgrade'
abbr -a bas  'bamos search'
abbr -a bal  'bamos list'

# Flatpak shortcuts
abbr -a fpi 'flatpak install'
abbr -a fpu 'flatpak update'
abbr -a fpr 'flatpak remove'
abbr -a fps 'flatpak search'
abbr -a fpl 'flatpak list'

# System shortcuts
abbr -a srr 'systemctl reboot'
abbr -a srp 'systemctl poweroff'
abbr -a ju  'journalctl -xe -n 50'

# Directory navigation
abbr -a ..   'cd ..'
abbr -a ...  'cd ../..'
abbr -a .... 'cd ../../..'

# Git shortcuts
abbr -a g    'git'
abbr -a gs   'git status'
abbr -a ga   'git add'
abbr -a gc   'git commit'
abbr -a gp   'git push'
abbr -a gl   'git log --oneline --graph'
abbr -a gd   'git diff'
abbr -a gco  'git checkout'

# Modern replacements (if uutils installed)
if command -v uu_ls >/dev/null 2>&1
    abbr -a ls 'lsd' 2>/dev/null || alias ls='ls --color=auto'
    abbr -a ll 'lsd -l' 2>/dev/null || alias ll='ls -l --color=auto'
    abbr -a la 'lsd -la' 2>/dev/null || alias la='ls -la --color=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -l --color=auto'
    alias la='ls -la --color=auto'
end

# ── BamOS welcome message ────────────────────────────────────────────────────
if status is-interactive
    and not set -q BAMOS_WELCOME_SHOWN
    set -g BAMOS_WELCOME_SHOWN 1
    echo (set_color brgreen)"🐉 BamOS "(set_color normal)"— Hệ điều hành Linux cho người Việt"
    echo "  bamos help  — Xem hướng dẫn sử dụng"
    echo "  bamos list  — Xem các gói đã cài đặt"
    echo ""
end

# ── Starship prompt (if installed) ──────────────────────────────────────────
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

# ── Zoxide smart cd (if installed) ──────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end
