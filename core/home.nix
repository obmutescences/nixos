{ pkgs, config, inputs, ... }: {

  imports = [
    # Programs
    ../home/programs/kitty
    ../home/programs/shell
    ../home/programs/fetch
    ../home/programs/git
    ../home/programs/thunar
    ../home/programs/lazygit
    ../home/programs/flameshot
	../home/programs/neovide
	../home/programs/atuin
	../home/programs/alacritty
	../home/programs/yazi
	../home/programs/bat
	../home/programs/neovim


    # Scripts
    ../home/scripts # All scripts

    # System (Desktop environment like stuff)
    ../home/system/hyprland
    ../home/system/hypridle
    ../home/system/hyprlock
    ../home/system/hyprpanel
    # ../home/system/hyprpaper
    ../home/system/wofi
    ../home/system/zathura
    ../home/system/udiskie
    ../home/system/clipman
    ../home/system/fctix5
	../home/system/mime
	../themes/gtk.nix

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
	  rye
	  python313Packages.ipython
	  python313Packages.pylatexenc

      # Utils
      zip
      unzip
      optipng
      pfetch
      pandoc
      btop
	  delta

      firefox
	  inputs.zen-browser.packages."${system}".default

      # Temp
      mpv
      pnpm
      realvnc-vnc-viewer
    ];
  };
}
