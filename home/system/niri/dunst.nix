{ pkgs, ... }:
{
	xdg.configFile."dunst/dunstrc".source = ./dunst/dunstrc;
}
