{ config, ... }: {
  imports = [
    # ../../nixos/nvidia.nix
	./net.nix
	./pkg.nix

	# core
	../../core/nixos.nix

    ./hardware-configuration.nix
    ./variables.nix
  ];

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "24.05";
}
