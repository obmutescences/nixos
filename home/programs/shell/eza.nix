# Eza is a ls replacement
{
  programs.eza = {
    enable = true;
    icons = "auto";

    extraOptions = [
      "--group-directories-first"
      "--no-quotes"
      "--icons=always"
    ];
  };
}
