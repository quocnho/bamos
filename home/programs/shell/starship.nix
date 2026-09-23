# Description: Starship prompt theme & cấu hình hiển thị
{ ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$python$container$cmd_duration$jobs\n$character";

      directory = {
        truncation_length = 3;
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      git_branch.style = "bold purple";
      git_status.style = "bold red";

      cmd_duration = {
        min_time = 1000;
        show_milliseconds = true;
        format = "took [$duration]($style) ";
        style = "yellow";
      };

      jobs = {
        threshold = 1;
        style = "blue";
      };

      container = {
        symbol = "";
        format = "[$symbol]($style) ";
        style = "bright-magenta";
      };

      python = {
        format = "[$symbol$version]($style) ";
        style = "green";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };
}
