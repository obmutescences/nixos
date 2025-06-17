{ pkgs, inputs, ... }:
{
	xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
	xdg.configFile."waybar/style.css".source = ./waybar/style.css;
	xdg.configFile."waybar/theme.css".source = ./waybar/theme.css;
}
