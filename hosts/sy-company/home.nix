{ pkgs, config, inputs, ... }: {

  imports = [
    ./variables.nix

	../../core/home.nix
  ];

  home = {
    # Import my profile picture, used by the hyprpanel dashboard
    file.".face.icon" = { source = ./profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
