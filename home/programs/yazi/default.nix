{
  pkgs,
  ...
}: {
  # terminal file manager
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
	shellWrapperName = "ya";
  };

  xdg.configFile."yazi/theme.toml".source = ./theme.toml;
  xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;
}
