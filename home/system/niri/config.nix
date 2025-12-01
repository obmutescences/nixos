{ pkgs, inputs, ... }:
{
	home.packages = [ 
		pkgs.xwayland-satellite
		# inputs.matugen-src.packages.${pkgs.stdenv.hostPlatform.system}.default
		# pkgs.swww
	];
	# services.swww.enable = true;
	
	# xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
