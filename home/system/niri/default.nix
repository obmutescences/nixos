{ pkgs, ... }:
{
	programs.waybar.enable = true;
	programs.niri = {
		enable = true;
		package = pkgs.niri;  
	};

	home.file.".config/niri" = {
		recursive = true;
		source = ./niri;
	};
}
