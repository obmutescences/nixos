{ pkgs, ... }: {
  xdg.portal = {
    enable = true;
    config.common.default = "gnome";
    # wlr.enable = true;
    xdgOpenUsePortal = true;
	config.niri = {
		  # default = "wlr";
		  "org.freedesktop.impl.portal.Access" = "gtk";
		  "org.freedesktop.impl.portal.Notification" = "gtk";
		  "org.freedesktop.impl.portal.FileChooser" = "gtk";
		  # "org.freedesktop.impl.portal.Secret" = "kwallet"; # needs to be tested
		  # "org.freedesktop.impl.portal.ScreenCast" = "wlr";
		  # "org.freedesktop.impl.portal.Screenshot" = "wlr";
    };
    extraPortals =
      [ 
	  # pkgs.xdg-desktop-portal-hyprland
	  # pkgs.xdg-desktop-portal-wlr
	  pkgs.xdg-desktop-portal-gtk
	  pkgs.xdg-desktop-portal-gnome
	  # pkgs.xdg-desktop-portal
	  ];
  };
}
