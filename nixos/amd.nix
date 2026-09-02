{ lib, pkgs, config, ... }:
{
	services.xserver.videoDrivers = [ "amdgpu" ];
	hardware = {
		# remote control (rustdesk) Wayland input injection via /dev/uinput
		uinput.enable = true;
		graphics = {
		enable = true;
		enable32Bit = true;
		extraPackages = with pkgs; [
			mesa
			egl-wayland
      ];
    };
  };
}
