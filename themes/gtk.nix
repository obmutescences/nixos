{
  pkgs,
  config,
  inputs,
  ...
}:
let
  # 检查 dracula-theme 支持的变体名称
  # dracula-theme = pkgs.dracula-theme;
in {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      home.pointerCursor = {
		enable = true;
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 18;
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk2";
      };

      gtk = {
        enable = true;
        theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
        };
        iconTheme = {
		  name = "Dracula";
		  package = pkgs.dracula-icon-theme;
        };
        gtk3.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };
        gtk4.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };
		font = {
		  name = "Monaspace Radon NF";
		  size = 11;
		};
      };
}
