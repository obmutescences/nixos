{ pkgs, config, inputs,... }:
let
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
  myAlure = pkgs.callPackage ../home/programs/deps/alure.nix {};
  myBucklespring = pkgs.callPackage ../home/programs/buckle/default.nix { alure = myAlure; };
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
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.appimage.package = pkgs.appimage-run.override {
	  extraPkgs = pkgs: [
		pkgs.libepoxy
		# 可能其他库
	  ];
  };
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
	  # 在此添加 `rye` 所需的动态库
	];

  services.displayManager.dms-greeter = {
	enable = true;
	compositor.name = "niri";  # Or "hyprland" or "sway"
	configHome = "/home/zerone";
	configFiles = [
		"/home/zerone/.config/DankMaterialShell/settings.json"
	];
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

  environment.sessionVariables = {
	XDG_CURRENT_DESKTOP = "niri";
	XDG_SESSION_TYPE = "wayland";
	XDG_SESSION_DESKTOP = "niri";
	NIXOS_OZONE_WL = "1";
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

  environment.systemPackages = with pkgs; [
    fd
    bc
    gcc
	pkg-config
    git-ignore
    xdg-utils
    wget
    curl
	gnumake
	fzf
    zip
	unzip
	cmake
	dust
	gping
	openssl
	xclip
	font-manager
    wl-clipboard
	cliphist
    brightnessctl
	# qt
	adwaita-qt6
	adwaita-qt
	adwaita-icon-theme
	# gtk
	nwg-look
	# keyboard sound
	# bucklespring-libinput
	myBucklespring
	# tools
	busybox
	# net proxy
    dae
	flclash
	clash-verge-rev
	# wallerpaper
	inputs.swww.packages.${pkgs.stdenv.hostPlatform.system}.swww
	# office
	libreoffice

	# music
	# spotube
	# spotify

	# bar
	# waybar

	# niri need
	xwayland-satellite
	dunst

	# keyboard control cursor
	wl-kbptr
	wlrctl

	# chat
	# wechat-uos
	wechat
	telegram-desktop
	# soc
	discord

	# display recording
	wf-recorder
	# mp4 压缩
	ffmpeg

	# quickshell need
	kdePackages.kdialog
	ddcutil
	# libsForQt5.qt5ct
	kdePackages.qt6ct
	matugen

	# ---dev---
	# editor
	# zed-editor
	protobuf
	# cli http request
	xh
	# manager docker in term
	oxker
	# neovim need
	neovim
	tree-sitter
	prettierd
	stylua
	lldb_20
	# mysql cli tools
	mycli
	# mysql backup tools
	mydumper
	# (callPackage ../home/programs/mydumper/default.nix {})

	rustup
	# ---dev---

	# sql cli tools
	rainfrog

	# music cli
	go-musicfox

	# recording and streaming
	obs-studio

	# Chinese calendar viewer
	ccal

	# go
	# TODO: locking with 1.26. update when upgrade.
	go_1_26
	
	# xdg
	xdg-desktop-portal-gnome
	xdg-desktop-portal-gtk
	xdg-desktop-portal
	gnome-keyring
	nautilus

	# fetch
	fastfetch

	# new nix cli tools
	nh
  ];
}
