# Hyprpaper is used to set the wallpaper on the system
{
  # The wallpaper is set by stylix
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
	  preload = [ "/home/zerone/Pictures/Wallpapers/desktop.jpg" ];
	  wallpaper = [
		"DP-1,/home/zerone/Pictures/Wallpapers/desktop.jpg"
		"DP-5,/home/zerone/Pictures/Wallpapers/desktop.jpg"
		];
    };
  };
}
