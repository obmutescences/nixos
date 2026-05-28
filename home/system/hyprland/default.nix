# So best window tiling manager
{ pkgs, config, inputs, ... }:
let
  border-size = config.var.theme.border-size;
  gaps-in = config.var.theme.gaps-in;
  gaps-out = config.var.theme.gaps-out;
  active-opacity = config.var.theme.active-opacity;
  inactive-opacity = config.var.theme.inactive-opacity;
  rounding = config.var.theme.rounding;
  blur = config.var.theme.blur;
  keyboardLayout = config.var.keyboardLayout;
in {

  imports = [
    # ./animations.nix
    # ./bindings.nix
    ./polkitagent.nix
  ];
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    hyprshot
    hyprpicker
    swappy
    imv
    wf-recorder
    wlr-randr
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
	inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus
  ];

  # services.swww.enable = true;
  xdg.configFile = {
	"hypr/hyprland.lua".source = ./hyprland.lua;
  };

  wayland.windowManager.hyprland = {
    enable = true;
	# package = pkgs.hyprland;
	package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
	plugins = [
		# inputs.hyprfocus.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus
		inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus
	];
    xwayland.enable = true;
    systemd.enable = true;
  };
  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
