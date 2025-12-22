{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    # wlr.enable = true;
    # xdgOpenUsePortal = true;
	config.niri = {
		  default = [
			"gnome"
			"gtk"
		  ];
		  "org.freedesktop.impl.portal.Access" = "gtk";
		  "org.freedesktop.impl.portal.Notification" = "gtk";
		  "org.freedesktop.impl.portal.FileChooser" = "gtk";
		  "org.freedesktop.impl.portal.Secret" = "kwallet"; # needs to be tested
    };
    extraPortals =
      [ 
	  pkgs.xdg-desktop-portal-hyprland
	  pkgs.xdg-desktop-portal-gtk
	  pkgs.xdg-desktop-portal
	  pkgs.xdg-desktop-portal-gnome
	  pkgs.xdg-desktop-portal-wlr
	  ];
  };
}
