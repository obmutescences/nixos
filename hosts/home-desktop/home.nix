{ pkgs, config, ... }: {

  imports = [
    ./variables.nix

    # Programs
    ../../home/programs/kitty
    ../../home/programs/shell
    ../../home/programs/fetch
    ../../home/programs/git
    ../../home/programs/thunar
    ../../home/programs/lazygit
    ../../home/programs/zen

    # Scripts
    ../../home/scripts # All scripts

    # System (Desktop environment like stuff)
    ../../home/system/hyprland
    ../../home/system/hypridle
    ../../home/system/hyprlock
    ../../home/system/hyprpanel
    ../../home/system/hyprpaper
    ../../home/system/wofi
    ../../home/system/zathura
    ../../home/system/mime
    ../../home/system/udiskie
    ../../home/system/clipman
    ../../home/system/fctix5

    #./secrets # CHANGEME: You should probably remove this line, this is where I store my secrets
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    packages = with pkgs; [
      vlc # Video player
      curtail

      # Dev
      go
      nodejs
      python3
      jq
      figlet
      just
      neovim

      # Utils
      zip
      unzip
      optipng
      pfetch
      pandoc
      btop

      firefox

      # Temp
      mpv
      pnpm
      realvnc-vnc-viewer
    ];

    # Import my profile picture, used by the hyprpanel dashboard
    file.".face.icon" = { source = ./profile_picture.png; };

    # Don't touch this
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
}
