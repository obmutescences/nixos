{ lib, pkgs, config, ... }:
{
	services.xserver.videoDrivers = [ "amdgpu" ];
	hardware = {
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
