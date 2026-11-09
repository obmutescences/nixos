{ pkgs, inputs, ... }: {
 xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
	inputs.loaf.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  config = {
    common = {
      default = [ "gtk" ];
	  "org.freedesktop.impl.portal.FileChooser" = "loaf";
    };
    niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "loaf" ];
    };
  };
  };
}
