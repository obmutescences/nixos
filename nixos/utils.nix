{ pkgs, config, inputs,... }:
let
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
  sddm-candy = pkgs.callPackage ../themes/sddm-candy.nix { };
in {

  networking.hostName = hostname;

  services = {
    xserver = {
      enable = true;
      xkb.layout = keyboardLayout;
      xkb.variant = "";
    };
    gnome.gnome-keyring.enable = true;
  };
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
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
	  # 在此添加 `rye` 所需的动态库
	];

  services = {
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
          compositor = "kwin";
        };
        package = pkgs.libsForQt5.sddm;
        extraPackages = with pkgs; [
          sddm-candy
          libsForQt5.qt5.qtquickcontrols # for sddm theme ui elements
          libsForQt5.layer-shell-qt # for sddm theme wayland support
          libsForQt5.qt5.qtquickcontrols2 # for sddm theme ui elements
          libsForQt5.qt5.qtgraphicaleffects # for sddm theme effects
          libsForQt5.qtsvg # for sddm theme svg icons
          libsForQt5.qt5.qtwayland # wayland support for qt5

        ];
        theme = "Candy";
        settings = {
          General = {
            GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
          };
          Theme = {
            ThemeDir = "/run/current-system/sw/share/sddm/themes";
            CursorTheme = "Bibata-Modern-Ice";
          };
        };
      };
      sessionPackages = [ pkgs.hyprland ];
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
	unzip
	cmake
	dust
	gping
	openssl
	xclip
	font-manager
	# sddm thememe
    sddm-candy
    libsForQt5.qt5.qtquickcontrols # for sddm theme ui elements
    libsForQt5.layer-shell-qt # for sddm theme wayland support
    libsForQt5.qt5.qtquickcontrols2 # for sddm theme ui elements
    libsForQt5.qt5.qtgraphicaleffects # for sddm theme effects
    libsForQt5.qtsvg # for sddm theme svg icons
    libsForQt5.qt5.qtwayland # wayland support for qt5
	libsForQt5.fcitx5-qt
	# qt
	adwaita-qt6
	adwaita-qt
	adwaita-icon-theme
	# gtk
	nwg-look
	# keyboard sound
	bucklespring-libinput
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
	wechat-uos
	telegram-desktop
	# soc
	discord
	
	# inputs.quickshell.packages.${pkgs.system}.quickshell
	# quickshell need
	kdePackages.kdialog
	cliphist
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
	mydumper

	rustup
	# ---rust 项目开发所需,后续不用可删除
    stdenv.cc          # 提供 gcc/linker 等基础工具
    clang
    libclang.lib
    llvmPackages.libcxxClang
	# ---rust 项目开发所需,后续不用可删除
	# ---dev---

  ];

  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';
}
