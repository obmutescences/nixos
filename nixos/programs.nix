{ pkgs, config, inputs,... }:
let 
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
in {
  networking.hostName = hostname;
  console.keyMap = keyboardLayout;

  environment.variables = {
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    EDITOR = "nvim";
  };

  services.libinput.enable = true;
  programs.dconf.enable = true;
  programs.appimage = {
	enable = true;
	binfmt = true;
	package = pkgs.appimage-run.override  {
		extraPkgs = pkgs: [
			pkgs.libepoxy
			pkgs.gtk3
			pkgs.webkitgtk_4_1
			pkgs.wayland
			pkgs.libglvnd
		];
	};
  };
  programs.nix-ld = {
	enable = true;
	libraries = with pkgs; [

	];
  };

   imports = [
	  inputs.noctalia-greeter.nixosModules.default
   ];

	programs.noctalia-greeter = {
	  enable = true;
	  package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;

	  # Optional configuration
	  greeter-args = "";
	  settings.cursor = {
		theme = "Adwaita";
		size = 24;
		package = pkgs.adwaita-icon-theme;
	  };
	};
	#  services.displayManager.dms-greeter = {
	# enable = true;
	# compositor.name = "niri";  # Or "hyprland" or "sway"
	# configHome = "/home/zerone";
	# configFiles = [
	# 	"/home/zerone/.config/DankMaterialShell/settings.json"
	# ];
	#  };

  programs.qylock = {
    enable    = true;
    theme     = "forest";     # Quickshell lockscreen theme
	sddm.enable = true; 
	quickshell.enable = true;
    # sddmTheme = "clockwork";     # optional: also sets services.displayManager.sddm.theme

    # Optional: fonts for themes that require licensed fonts not in the repo.
    # Drop the font file(s) in your config directory and reference them here.
    # sddmThemeFonts = [ ./fonts/zhcn.ttf ];
  };

  services.geoclue2.enable = true;  # For QtPositioning

  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;
  };

  qt.enable = true;

  services = {
    xserver = {
      enable = true;
      xkb.layout = keyboardLayout;
      xkb.variant = "";
    };
    gnome.gnome-keyring.enable = true;
    dbus.enable = true;
    gvfs.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    udisks2.enable = true;
	displayManager = {
      # sessionPackages = [ pkgs.niri-unstable inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland ];
      sessionPackages = [ pkgs.niri-unstable ];
	  defaultSession = "niri";
    };
  };

  # Faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  systemd.services.mouseless = {
    description = "Keyboard-driven mouse for Wayland";
    wantedBy = [ "multi-user.target" ];
    after = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "/home/zerone/.local/bin/mouseless --config /home/zerone/.config/mouseless/config.yaml";
      
      # 运行用户：需要能访问输入设备（通常为 root 或 input 组）
      User = "root";  # 或 "your-username"
      
      # 如果需要访问 Wayland socket 和输入设备：
      SupplementaryGroups = [ "input" "wheel" ];
      
      # 环境变量（如果需要）
      # Environment = [
      #   "XDG_RUNTIME_DIR=/run/user/1000"  # 替换为你的 UID
      #   "WAYLAND_DISPLAY=wayland-1"
      # ];
      
      # 重启策略
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
