{
  pkgs,
  config,
  inputs,
  ...
}:
let
  # 检查 dracula-theme 支持的变体名称
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
          name = "Catppuccin";
          package = pkgs.catppuccin-gtk;
        };
        iconTheme = {
		  name = "Fluent";
		  package = pkgs.fluent-icon-theme;
        };
        gtk3.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };
        gtk4.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
			gtk-theme-name=catppuccin-frappe-blue-standard
          '';
        };
		font = {
		  name = "Monaspace Radon NF";
		  size = 11;
		};
      };
}
