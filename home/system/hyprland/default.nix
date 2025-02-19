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
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
  ];
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    libsForQt5.qt5ct
    qt6ct
    hyprshot
    hyprpicker
    swappy
    imv
    wf-recorder
    wlr-randr
    wl-clipboard
    brightnessctl
    gnome-themes-extra
    libva
    dconf
    wayland-utils
    wayland-protocols
    glib
    direnv
    meson
  ];

  wayland.windowManager.hyprland = {
    enable = true;
	plugins = [
		(pkgs.hyprlandPlugins.hyprscroller.overrideAttrs {
            src = pkgs.fetchFromGitHub {
              owner = "dawsers";
              repo = "hyprscroller";
              rev = "686bf83316be96cbaed980b63ad43514cf0dce3c";
              hash = "sha256-SnVsSRDltmFKjTvJo3hecYqhoKzwlbVc/Vy57F5+j5Y=";
        };
		})
	];
    xwayland.enable = true;
    systemd.enable = true;
	package = pkgs.hyprland;
	# package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    # portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
	  "$browser" = "zen";

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
		"FlClash"
		"buckle -p ~/.config/nixos/home/sources/keybord-sound/alpacas -g 100 -s 100"
      ];

      monitor = [
        "DP-5,3840x2160@143.99,auto,1"
        "DP-1,2560x1440@180.00,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "ANKI_WAYLAND,1"
        "DISABLE_QT5_COMPAT,0"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        # "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "GTK_THEME,FlatColor:dark"
        # "GTK2_RC_FILES,/home/hadi/.local/share/themes/FlatColor/gtk-2.0/gtkrc"
        # "__GL_GSYNC_ALLOWED,0"
        # "__GL_VRR_ALLOWED,0"
        "DISABLE_QT5_COMPAT,0"
        "DIRENV_LOG_FORMAT,"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "XDG_SESSION_TYPE,wayland"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
		"QT_QPA_PLATFORMTHEME,qt6ct"
		"GDK_BACKEND,wayland,x11,*"
		"GDK_SCALE,1"

		"GLFW_IM_MODULE,fcitx"
		"GTK_IM_MODULE,fcitx"
		"INPUT_METHOD,fcitx"
		"XMODIFIERS,@im=fcitx"
		"IMSETTINGS_MODULE,fcitx"
		"QT_IM_MODULE,fcitx"

      ];

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        border_part_of_window = true;
        # layout = "dwindle";
		layout = "scroller";
      };

      decoration = {
        rounding = rounding;
        shadow = {
          enabled = false;
          range = 20;
          render_power = 3;
        };
        blur = { 
	    enabled = true;
	    size = 5;
        passes = 3;
	    vibrancy = 0.7;
        new_optimizations = true;
        ignore_opacity = true;
        xray = false;
		popups = true;
		popups_ignorealpha = 0.4;
		input_methods = true;
		input_methods_ignorealpha = 0.3;
		special = true;
	};
      };

      master = {
        new_status = true;
      };

      gestures = { workspace_swipe = true; };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
		vrr = 0;
		force_default_wallpaper = 0;
      };

      windowrulev2 =
        [ 
		"opacity 0.67 0.67,class:.*"
		"opacity 0.99 0.99,class:^(neovide)$"
		"float,class:^(org.kde.dolphin)$,title:^(Progress Dialog — Dolphin)$"
		"float,class:^(org.kde.dolphin)$,title:^(Copying — Dolphin)$"
		"float,class:^(firefox)$,title:^(Picture-in-Picture)$"
		"float,class:^(firefox)$,title:^(Library)$"
		"float,class:^(kitty)$,title:^(top)$"
		"float,class:^(kitty)$,title:^(btop)$"
		"float,class:^(kitty)$,title:^(htop)$"
		"float,class:^(vlc)$"
		"float,class:^(kvantummanager)$"
		"float,class:^(qt5ct)$"
		"float,class:^(qt6ct)$"
		"float,class:^(nwg-look)$"
		"float,class:^(org.kde.ark)$"
		"float,class:^(org.pulseaudio.pavucontrol)$"
		"float,class:^(blueman-manager)$"
		"float,class:^(.blueman-manager-wrapped)$"
		"float,class:^(nm-applet)$"
		"float,class:^(nm-connection-editor)$"
		"float,class:^(org.kde.polkit-kde-authentication-agent-1)$"
		];

      # layerrule = [ "noanim, launcher" "noanim, ^ags-.*" ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
		force_no_accel = 1;
        sensitivity = 1;
        repeat_delay = 200;
        repeat_rate = 80;

      };
    };
  };
  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
