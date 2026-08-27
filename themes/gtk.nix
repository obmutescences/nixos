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
        platformTheme.name = "gtk4";
      };

      gtk = {
        enable = true;
        theme = {
          name = "catppuccin-frappe-blue-standard";
          package = pkgs.catppuccin-gtk;
        };
        iconTheme = {
		  name = "Fluent";
		  package = pkgs.fluent-icon-theme;
        };
        gtk3.extraConfig = {
            gtk-application-prefer-dark-theme=1;
        };
        gtk4.extraConfig = {
            gtk-application-prefer-dark-theme=1;
        };
        # noctalia 生成的颜色定义（@import 必须放在最前）
        gtk3.extraCss = ''
          @import url("noctalia.css");
        '';
        gtk4.extraCss = ''
          @import url("noctalia.css");
        '';
		font = {
		  name = "Monaspace Radon NF";
		  size = 11;
		};
      };
}
