{ pkgs, config, inputs,... }:
let
  myAlure = pkgs.callPackage ../home/programs/deps/alure.nix {};
  myBucklespring = pkgs.callPackage ../home/programs/buckle/default.nix { alure = myAlure; };
in {
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
