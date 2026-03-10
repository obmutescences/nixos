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
  ];

  # services.swww.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
	# package = pkgs.hyprland;
	package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
	plugins = [
		inputs.hyprfocus.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus
	];
    xwayland.enable = true;
    systemd.enable = true;

	extraConfig = "
scrolling {
  column_width = 0.4
  fullscreen_on_one_column = false
}
source = /home/zerone/.config/hypr/dms/colors.conf
source = /home/zerone/.config/hypr/dms/shadow.conf
	";

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
	  "$browser" = "zen-beta";

      exec-once = [
		"gsettings set org.gnome.desktop.interface gtk-theme adwaita-dark"
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        "dbus-update-activation-environment --all"
		"sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
		"fcitx5 -d --replace"
		"dms run"
		"FlClash"
		"keybord-sound-nkcream"
      ];

      monitor = [
        "DP-5,3840x2160@143.99,auto,1.2"
        "DP-1,2560x1440@180.00,auto,1"
      ];

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        # "SDL_VIDEODRIVER,wayland"
		# "CLUTTER_BACKEND,wayland"
		"QT_QPA_PLATFORMTHEME,qt6ct"
		"GDK_BACKEND,wayland,x11,*"
		# "OZONE_PLATFORM,wayland"
		# "EGL_PLATFORM,wayland"
		"GDK_SCALE,1"
		"WLR_RENDERER_ALLOW_SOFTWARE,1"

		# "GLFW_IM_MODULE,fcitx"
		# "GTK_IM_MODULE,fcitx"
		# "INPUT_METHOD,fcitx"
		"XMODIFIERS,@im=fcitx"
		# "IMSETTINGS_MODULE,fcitx"
		"QT_IM_MODULE,fcitx"
		"SDL_IM_MODULE,fcitx"

		"BROWSER,zen-beta"
      ];

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "scrolling";
		"col.active_border" = "rgba(e67e80ff) rgba(dbbc7fff) 45deg";
		"col.inactive_border" = "rgba(1e8b50d9) rgba(50b050d9) 45deg";
      };

      decoration = {
        rounding = rounding;
		dim_inactive = true;
		dim_strength = 0.4;
        shadow = {
          enabled = true;
		  color = "rgba(e67e80ff)";
		  color_inactive = "rgba(62, 67, 46, 0.9)";
		  range = 40;
        };
        blur = {
			enabled = true;
			size = 4;
			passes = 3;
			new_optimizations = true;
			ignore_opacity = true;
			xray = false;
			popups = true;
			popups_ignorealpha = 0.5;
			input_methods = true;
			input_methods_ignorealpha = 0.5;
			special = true;
			vibrancy=0.500000;
			vibrancy_darkness=0.7;

	     };
	   };

      master = {
        new_status = true;
      };

      gestures = { };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
		vrr = 0;
		force_default_wallpaper = 0;
      };

      windowrule =
        [
          "match:class .*, opacity 0.8"
          "match:class ^(neovide)$, opacity 0.99 0.99"
          "match:class ^(org.kde.dolphin)$ title:^(Progress Dialog — Dolphin)$, float on"
          "match:class ^(org.kde.dolphin)$ title:^(Copying — Dolphin)$, float on"
          "match:class ^(firefox)$ title:^(Picture-in-Picture)$, float on"
          "match:class ^(firefox)$ title:^(Library)$, float on"
          "match:class ^(kitty)$ title:^(top)$, float on"
          "match:class ^(kitty)$ title:^(btop)$, float on"
          "match:class ^(kitty)$ title:^(htop)$, float on"
          "match:class ^(vlc)$, float on"
          "match:class ^(kvantummanager)$, float on"
          "match:class ^(qt5ct)$, float on"
          "match:class ^(qt6ct)$, float on"
          "match:class ^(nwg-look)$, float on"
          "match:class ^(org.kde.ark)$, float on"
          "match:class ^(org.pulseaudio.pavucontrol)$, float on"
          "match:class ^(blueman-manager)$, float on"
          "match:class ^(.blueman-manager-wrapped)$, float on"
          "match:class ^(nm-applet)$, float on"
          "match:class ^(nm-connection-editor)$, float on"
          "match:class ^(org.kde.polkit-kde-authentication-agent-1)$, float on"
          "match:class ^(flameshot-pin)$, float on"
          "match:class ^(flameshot-pin)$, pin on"
          "match:class ^(Alacritty)$, float on"
          "match:class ^(com.mitchellh.ghostty)$, float on"
          "match:title ^(illogical-impulse Settings)$, float on"
          "match:title .*Shell conflicts.*, float on"
          "match:class ^(org.freedesktop.impl.portal.desktop.kde)$, float on"
          "match:class ^(org.freedesktop.impl.portal.desktop.kde)$, size 60% 65%"
          "match:title ^([Pp]icture[-s]?[Ii]n[-s]?[Pp]icture)(.*)$, float on"
          "match:title ^([Pp]icture[-s]?[Ii]n[-s]?[Pp]icture)(.*)$, move 73% 72%"
          "match:title ^([Pp]icture[-s]?[Ii]n[-s]?[Pp]icture)(.*)$, size 25%"
          "match:title ^([Pp]icture[-s]?[Ii]n[-s]?[Pp]icture)(.*)$, pin on"
          "match:class ^(firefox)$, opacity 0.99 0.99"
          "match:class ^(QQ)$ title:^(QQ)$, tile on"
          "match:class ^(wechat)$, opacity 0.96 0.96"
          "match:class ^(wechat)$ title:^(图片和视频)$, tile on"
          "match:class ^(wechat)$ title:^(图片和视频)$, float on"
        ];

      layerrule = [
			"blur on, match:namespace dms:bar"
			"blur_popups on, match:namespace quickshell:.*"
			"blur on, match:namespace quickshell:.*"
	  ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0.6;
        repeat_delay = 200;
        repeat_rate = 80;

	  };
	  plugin = {
		  hyprfocus = {
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
			  "realsmooth, 0.28,0.29,0.69,1.08"
			];
			flash = {
				flash_opacity = 0.7;
				in_bezier = "realsmooth";
				in_speed = 0.5;
				out_bezier = "realsmooth";
				out_speed = 3;
			};
			shrink = {
				shrink_percentage = 0.85;
				in_bezier = "realsmooth";
				in_speed = "6.5";
				out_bezier = "realsmooth";
				out_speed = "6.0";
			};
		  };
	  };
    };
  };
  systemd.user.targets.hyprland-session.Unit.Wants =
    [ "xdg-desktop-autostart.target" ];
}
