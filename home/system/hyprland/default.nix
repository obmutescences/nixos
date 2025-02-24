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
              hash = "sha256-PBWQxO15VbM4oh8wAe1nibugNbgSITXQbOC59162JTo=";
        };
		})
		(pkgs.hyprlandPlugins.hyprfocus.overrideAttrs {
            src = pkgs.fetchFromGitHub {
              owner = "daxisunder";
              repo = "hyprfocus";
			  rev = "227378fe742034c87a36fdb0681083da49bd6c99";
			  hash = "sha256-ST5FFxyw5El4A7zWLaWbXb9bD9C/tunU+flmNxWCcEY=";
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
		"gsettings set org.gnome.desktop.interface gtk-theme adwaita-dark"
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
		"fcitx5 -d --replace"
		"FlClash"
		"buckle -p ~/.config/nixos/home/sources/keybord-sound/alpacas -g 100 -s 100"
		"swww-daemon"
		"set-wallpaper"
      ];

      monitor = [
        "DP-5,3840x2160@143.99,auto,1"
        "DP-1,2560x1440@180.00,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "SDL_VIDEODRIVER,wayland"
		"CLUTTER_BACKEND,wayland"
		"QT_QPA_PLATFORMTHEME,qt6ct"
		"GDK_BACKEND,wayland,x11,*"
		"OZONE_PLATFORM,wayland"
		"EGL_PLATFORM,wayland"
		"GDK_SCALE,1"
		"WLR_RENDERER_ALLOW_SOFTWARE,1"

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
		"col.active_border" = "rgba(90ceaaff) rgba(ecd3a0ff) 45deg";
		"col.inactive_border" = "rgba(1e8b50d9) rgba(50b050d9) 45deg";
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
		popups_ignorealpha = 0.5;
		input_methods = true;
		input_methods_ignorealpha = 0.5;
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
		"float,class:^(flameshot)$"
		"pin,class:^(flameshot)$"
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
	  "plugin:hyprfocus" = {
		enabled = true;
		keyboard_focus_animation = "shrink";
		mouse_focus_animation = "shrink";
		animate_floating = false;
		animate_workspacechange = true;
		focus_animation = "shrink";
		bezier = [
		  "bezIn, 0.5,0.0,1.0,0.5"
		  "bezOut, 0.0,0.5,0.5,1.0"
		  "overshot, 0.05, 0.9, 0.1, 1.05"
		  "smoothOut, 0.36, 0, 0.66, -0.56"
		  "smoothIn, 0.25, 1, 0.5, 1"
		  "realsmooth, 0.28,0.29,.69,1.08"
        ];
		flash = {
			flash_opacity = 0.7;
			in_bezier = "realsmooth";
			in_speed = 0.5;
			out_bezier = "realsmooth";
			out_speed = 3;
		};
		shrink = {
			shrink_percentage = 0.75;
			in_bezier = "realsmooth";
			in_speed = "6.5";
			out_bezier = "realsmooth";
			out_speed = "6.0";
		};
	  };
    };
  };
  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
