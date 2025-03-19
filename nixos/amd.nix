{ lib, pkgs, config, ... }:
{
	services.xserver.videoDrivers = [ "amdgpu" ];
	hardware.opengl.extraPackages = with pkgs; [
		rocm-opencl-icd
		rocm-opencl-runtime
	 ];
	hardware.opengl.driSupport = true;
	hardware = {
		graphics = {
		enable = true;
		enable32Bit = true;
		extraPackages = with pkgs; [
			mesa
			egl-wayland
			amdvlk
      ];
    };
  };
}
