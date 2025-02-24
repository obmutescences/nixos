{
  pkgs,
  config,
  inputs,
  ...
}:
let
  catppuccin-gtk = pkgs.catppuccin-gtk.overrideAttrs {
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "gtk";
      rev = "v1.0.3";
      fetchSubmodules = true;
      hash = "sha256-q5/VcFsm3vNEw55zq/vcM11eo456SYE5TQA3g2VQjGc=";
    };
    postUnpack = "";
  };
in {
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 18;
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
      };

      gtk = {
        enable = true;
        theme = {
          name = "catppuccin-mocha-mauve-compact";
          package = catppuccin-gtk.override {
            accents = ["mauve"];
            variant = "mocha";
            size = "compact";
          };
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
		  name = "Comic Code";
		  size = 13;
		};
      };
}
