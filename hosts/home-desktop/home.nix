{ pkgs, config, inputs, lib,... }: {

  imports = [
    ./variables.nix

	../../core/home.nix
  ];

  nixpkgs.overlays = lib.mkForce null;

  home = {
    # Import my profile picture, used by the hyprpanel dashboard
    file.".face.icon" = { source = ./profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
