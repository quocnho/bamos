# Description: Cấu hình Zsh shell & keybindings
{ ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true;
      share = true;
    };

    initContent = ''
      setopt autocd
      setopt no_beep
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
    '';
  };
}
