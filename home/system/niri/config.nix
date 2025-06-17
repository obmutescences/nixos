{ pkgs, inputs, ... }:
{
	home.packages = [ 
		pkgs.xwayland-satellite
		pkgs.swww
	];
	# programs.waybar.enable = true;
	services.swww.enable = true;
	
	# environment.sessionVariables.NIXOS_OZONE_WL = "1";

	xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
	# home.file.".config/niri" = {
	# 	recursive = true;
	# 	source = ./niri;
	# };
}
