{ pkgs, inputs, ... }:
{
	home.packages = [ 
		pkgs.xwayland-satellite
		# pkgs.swww
	];
	# services.swww.enable = true;
	
	# xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
