{ config, ... }: {
  imports = [
    ../../nixos/nvidia.nix

	# core
	../../core/nixos.nix

	# pkg
	./pkg.nix

    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "24.05";
}
