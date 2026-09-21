# Description: Cấu hình Tmux (craftzdog workflow: tmux + editor)
{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "a"; # prefix C-a
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 10000;
    escapeTime = 0;

    extraConfig = ''
      set -g renumber-windows on
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };
}
