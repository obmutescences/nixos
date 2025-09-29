{
  imports = [
    ../nixos/audio.nix
    ../nixos/auto-upgrade.nix
    ../nixos/bluetooth.nix
    ../nixos/fonts.nix
    ../nixos/home-manager.nix
    ../nixos/network-manager.nix
    ../nixos/nix.nix
    ../nixos/systemd-boot.nix
    ../nixos/timezone.nix
    # ../../nixos/tuigreet.nix
    ../nixos/users.nix
    ../nixos/utils.nix
    ../nixos/xdg-portal.nix
    ../nixos/variables-config.nix
    ../nixos/docker.nix
	../home/system/dae/default.nix
	# ./fhs.nix

	# niri
	../home/system/niri

    # Choose your theme here
    # ../themes/stylix/2025.nix
	];
}
