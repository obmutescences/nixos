{ pkgs, inputs, ... }:
{
	# home.packages = [ pkgs.xwayland-satellite ];
	# programs.waybar.enable = true;
	nixpkgs.overlays = [inputs.niri.overlays.niri];
	imports = [inputs.niri.nixosModules.niri];
	programs.niri = {
		enable = true;
		package = pkgs.niri-unstable;  
	};
	
	# environment.sessionVariables.NIXOS_OZONE_WL = "1";

	# xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
	# home.file.".config/niri" = {
	# 	recursive = true;
	# 	source = ./niri;
	# };
}
