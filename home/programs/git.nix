# Description: Cấu hình Git, Delta pager và SSH client
{ ... }:

{
  # Git
  programs.git = {
    enable = true;
    settings = {
      alias = {
        st = "status";
        co = "checkout";
        br = "branch -a";
        ci = "commit";
        lg = "log --oneline --graph --decorate -20";
        pl = "pull --rebase";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";
    };
  };

  # Delta pager
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      line-numbers = true;
      navigate = true;
      syntax-theme = "GitHub";
    };
  };

  # SSH client
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
      };
    };
    matchBlocks = { };
  };
}
