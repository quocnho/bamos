# Description: Danh sách vim plugins từ nixpkgs & custom
{ pkgs, customPlugins }:

with pkgs.vimPlugins;
[
  # LSP & completion
  nvim-lspconfig
  blink-cmp
  friendly-snippets
  luasnip
  plenary-nvim

  # Syntax & text objects
  nvim-treesitter.withAllGrammars
  (nvim-treesitter-textobjects.overrideAttrs (o: {
    passthru = (o.passthru or { }) // {
      dependencies = [ ];
    };
  }))
  targets-vim

  # Navigation & search
  fzf-lua
  hop-nvim
  nvim-hlslens
  aerial-nvim

  # Editor helpers
  nvim-autopairs
  vim-sandwich
  vim-commentary
  vim-repeat
  yanky-nvim
  vim-eunuch
  vim-matchup
  vim-oscyank

  # Git
  vim-fugitive
  gitsigns-nvim

  # UI
  lualine-nvim
  bufferline-nvim
  which-key-nvim
  snacks-nvim
  nvim-colorizer-lua
  render-markdown-nvim
  statuscol-nvim
  nvim-ufo
  promise-async
  oil-nvim
  mini-icons
  fidget-nvim
  nvim-lightbulb
  nvim-bqf
  vim-illuminate
  todo-comments-nvim

  # Custom plugins
  nui-nvim
  customPlugins.my-note-nvim
  customPlugins.tiny-term-nvim

  # AI Assistant
  codecompanion-nvim

  # Themes
  tokyonight-nvim
  catppuccin-nvim
  gruvbox-material
  nightfox-nvim
  kanagawa-nvim
]
