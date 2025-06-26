{ pkgs, inputs, ... }:
{
	xdg.configFile."wl-kbptr/config".source = ./config;
}
