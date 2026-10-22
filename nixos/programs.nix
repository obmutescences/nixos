{ pkgs, config, inputs,... }:
let 
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
  # 预编译二进制 + config.yaml 都在 home/programs/mouseless/，见那里的 package.nix
  mouseless = pkgs.callPackage ../home/programs/mouseless/package.nix { };
in {
  # neovide 二进制来自 fork 仓库自带 flake 的 overlay：pkgs.neovide 换成
  # fork 源码编译的版本，home-manager 的 programs.neovide（默认取 pkgs.neovide）
  # 和 start-neovide 脚本里的 ${pkgs.neovide} 都指向同一份构建。
  nixpkgs.overlays = [ inputs.neovide.overlays.default ];

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

  # 按键音：home-manager 模块在 core/home.nix 里 import，这里统一启用/选配置
  # 配置目录：home/programs/keyboard-dances/sounds/<profile>/{press,release}.{wav,ogg}
  home-manager.users."${config.var.username}".programs = {
	keyboard-dances = {
		enable = true;
		# profile = "nk-cream";
		profile = "default";
	};

	# X11 ↔ Wayland 剪贴板桥（预编译二进制在 home/programs/clipferry/clipferry）
	clipferry.enable = true;
  };

   imports = [
	  inputs.noctalia-greeter.nixosModules.default
	  inputs.inir.nixosModules.inir
   ];

	# programs.noctalia-greeter = {
	#   enable = true;
	#   package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
	#
	#   # Optional configuration
	#   greeter-args = "";
	#   settings.cursor = {
	# 	theme = "Adwaita";
	# 	size = 24;
	# 	package = pkgs.adwaita-icon-theme;
	#   };
	# };

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
	   # sddm = "forest";     # optional: also sets services.displayManager.sddm.theme

	   # Optional: fonts for themes that require licensed fonts not in the repo.
	   # Drop the font file(s) in your config directory and reference them here.
	   # sddmThemeFonts = [ ./fonts/zhcn.ttf ];
	 };

  services.geoclue2.enable = true;  # For QtPositioning

  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

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

  # inir shell
  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ];
  };

  systemd.services.mouseless = {
    description = "Keyboard-driven mouse for Wayland";
    wantedBy = [ "multi-user.target" ];
    after = [ "graphical-session.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${mouseless}/bin/mouseless --config ${mouseless}/share/mouseless/config.yaml";
      
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
