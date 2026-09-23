# Description: Các shell aliases dùng chung (git, eza, nixos, bam...)
{ ... }:

{
  programs.zsh.shellAliases = {
    # eza
    ls = "eza --icons --group-directories-first";
    ll = "eza -lh --icons --git --group-directories-first";
    la = "eza -lah --icons --git --group-directories-first";
    lt = "eza --tree --icons --level=2";

    # Git
    g = "git";
    ga = "git add";
    gcm = "git commit -m";
    gco = "git checkout";
    gb = "git branch";
    gs = "git status";
    gd = "git diff";
    gl = "git log --oneline --graph --decorate -20";
    gp = "git push";
    gpl = "git pull";
    gac = "git add -A && git commit -m \"Update\"";

    # Others
    grep = "grep --color=auto";
    zi = "zoxide query -i";

    # Antigravity IDE
    antigravity = "antigravity-ide";
    agy = "agy";

    # NixOS rebuild & flake shortcuts (Bam CLI)
    sw = "bam switch";
    swu = "bam switch -u";
    bt = "bam boot";
    bu = "bam build";
    dry = "bam dry";
    fu = "bam lock";
    chk = "nix flake check /etc/nixos";
    ngc = "bam gc";
  };
}
