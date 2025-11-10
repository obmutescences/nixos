{ pkgs, config, inputs,... }:
let
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
  sddm-theme = inputs.silentSDDM.packages.${pkgs.system}.default.override {
      theme = "ken"; # select the config of your choice
  };
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
  
  qt.enable = true;
  # TODO: TEST
  programs.ssh.package = pkgs.openssh_10_2;

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
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
        package = pkgs.kdePackages.sddm;
		extraPackages = sddm-theme.propagatedBuildInputs;
		theme = sddm-theme.pname;
        settings = {
          General = {
			GreeterEnvironment = "QML2_IMPORT_PATH=${sddm-theme}/share/sddm/themes/${sddm-theme.pname}/components/,QT_IM_MODULE=qtvirtualkeyboard";
			InputMethod = "qtvirtualkeyboard";
          };
        };
      };
      sessionPackages = [ inputs.hyprland.packages.${pkgs.system}.hyprland ];
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

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

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
	# sddm-theme
	sddm-theme 
	sddm-theme.test
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
	inputs.swww.packages.${pkgs.system}.swww
	# office
	libreoffice

	# music
	spotube
	spotify

	# bar
	waybar
	
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
	
	# inputs.quickshell.packages.${pkgs.system}.quickshell
	# quickshell need
	kdePackages.kdialog
	ddcutil
	libsForQt5.qt5ct
	kdePackages.qt6ct
	matugen
	# dankmaterialshell
	inputs.dankmaterialshell.packages.${pkgs.system}.default

	# ---dev---
	# editor
	zed-editor
	protobuf
	# cli http request
	xh
	# manager docker in term
	oxker
	# neovim need
	tree-sitter
	prettierd
	stylua
	lldb_20
	# mysql cli tools
	mycli
	# mysql backup tools
	# TODO: using
	# mydumper
	(callPackage ../home/programs/mydumper/default.nix {})

	rustup
	# ---rust 项目开发所需,后续不用可删除
    stdenv.cc          # 提供 gcc/linker 等基础工具
    clang
    libclang.lib
    llvmPackages.libcxxClang
	# ---rust 项目开发所需,后续不用可删除
	# ---dev---

  ];
}
