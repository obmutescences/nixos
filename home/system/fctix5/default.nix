{
  pkgs,
  ...
}: {

  xdg.configFile = {
    "fcitx5/profile" = {
      source = ./profile;
      force = true;
    };
    "fcitx5/conf/classicui.conf".source = ./classicui.conf;
  };

  i18n.inputMethod = {
    # enabled = "fcitx5";
	type = "fcitx5";
	enable = true;
	fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      # for flypy chinese input method
      fcitx5-rime
      # needed enable rime using configtool after installed
      qt6Packages.fcitx5-configtool
      qt6Packages.fcitx5-chinese-addons
      # fcitx5-mozc    # japanese input method
      fcitx5-gtk # gtk im module
	  fcitx5-fluent
    ];
  };
}
