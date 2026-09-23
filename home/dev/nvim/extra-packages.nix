# Description: LSP servers, formatters, linters & CLI tools cho Neovim
{ pkgs }:

with pkgs;
[
  # LSP servers
  nil
  lua-language-server
  pyright
  typescript-language-server
  vue-language-server
  bash-language-server
  marksman
  yaml-language-server
  vscode-langservers-extracted
  taplo
  intelephense
  gopls
  clang-tools
  sqls
  tailwindcss-language-server

  # Formatters & Linters
  black
  ruff
  stylua
  nixfmt
  prettier
  blade-formatter

  # Tools
  fzf
  fd
  ripgrep
  bat
]
