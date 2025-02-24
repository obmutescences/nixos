{
  pkgs,
  ...
}: {
  # terminal file manager
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      manager = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };

  xdg.configFile."yazi/theme.toml".source = "./theme.toml";
  xdg.configFile."yazi/yazi.toml".source = "./yazi.toml";
  xdg.configFile."yazi/keymap.toml".source = "./keymap.toml";
}
