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

  services.swww.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
	# package = pkgs.hyprland;
	package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
	plugins = [
		# inputs.hyprland-plugins.packages.${pkgs.system}.hyprscrolling
		# inputs.hyprland-plugins.packages.${pkgs.system}.hyprfocus
		# (pkgs.callPackage ./hyprscroller.nix {})
		inputs.hyprscroller.packages.${pkgs.system}.hyprscroller
		inputs.hyprfocus.packages.${pkgs.system}.hyprfocus
		# (pkgs.callPackage ./hyprfocus.nix {})
	];
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
	  "$browser" = "zen";

      exec-once = [
		"gsettings set org.gnome.desktop.interface gtk-theme adwaita-dark"
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        "dbus-update-activation-environment --all"
		"sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
		"fcitx5 -d --replace"
		# "waybar &"
		# "qs -p /home/zerone/projects/dots-hyprland/.config/quickshell/ii"
		# "qs -c dms"
		"qs -p /home/zerone/Downloads/DankMaterialShell"
		"FlClash"
		# "clash-verge"
		# "dunst"
		"keybord-sound"
		"set-wallpaper"
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
        "SDL_VIDEODRIVER,wayland"
		"CLUTTER_BACKEND,wayland"
		"QT_QPA_PLATFORMTHEME,qt6ct"
		"GDK_BACKEND,wayland,x11,*"
		"OZONE_PLATFORM,wayland"
		"EGL_PLATFORM,wayland"
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
        # layout = "dwindle";
		# layout = "scrolling";
		layout = "scroller";
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

      gestures = { };

	  group = {
		auto_group = false;
	  };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
		vrr = 0;
		force_default_wallpaper = 0;
      };

      windowrule =
        [ 
		"opacity 0.8 0.8,class:.*"
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
		"float,title:^(flameshot-pin)$"
		"pin,title:^(flameshot-pin)$"
		"float,class:^(Alacritty)$"
		"float,class:^(com.mitchellh.ghostty)$"
		"float, title:^(illogical-impulse Settings)$"
		"float, title:.*Shell conflicts.*"
		"float, class:org.freedesktop.impl.portal.desktop.kde"
		"size 60% 65%, class:org.freedesktop.impl.portal.desktop.kde"
		"float, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"keepaspectratio, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"move 73% 72%, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"size 25%, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"float, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"pin, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
		"float, class:^(QQ)$"
		"tile, class:^(QQ)$,title:^(QQ)$"
		"float, class:^(wechat)$"
		"tile, class:^(wechat)$,title:^(微信)$"

		# Disable blur for xwayland context menus
		# "noblur,class:^(wechat)$,title:^(wechat)$"
		"bordersize 0,class:^(wechat)$,title:^(wechat)$"
		# "noblur, xwayland:1"
		];

      layerrule = [ 
			"blur, waybar"
			"blur, quickshell:bar"
			# quickshell
			"blur, quickshell"
			"blurpopups, quickshell:.*"
			"blur, quickshell:.*"
			"ignorealpha 0.79, quickshell:.*"
			"animation slide, quickshell:bar"
			"animation slide, quickshell:verticalBar"
			"animation fade, quickshell:screenCorners"
			"animation slide right, quickshell:sidebarRight"
			"animation slide left, quickshell:sidebarLeft"
			"animation slide top, quickshell:wallpaperSelector"
			"animation slide bottom, quickshell:osk"
			"animation slide bottom, quickshell:dock"
			"animation slide bottom, quickshell:cheatsheet"
			"blur, quickshell:session"
			"noanim, quickshell:session"
			"ignorealpha 0, quickshell:session"
			"animation fade, quickshell:notificationPopup"
			"blur, quickshell:backgroundWidgets"
			"ignorealpha 0.05, quickshell:backgroundWidgets"
			"noanim, quickshell:screenshot"
			"animation popin 120%, quickshell:screenCorners"
			"noanim, quickshell:lockWindowPusher"
			"noanim, quickshell:overview"
			"noanim, gtk4-layer-shell"
			"blur, shell:bar"
			"ignorezero, shell:bar"
			"blur, shell:notifications"
	  ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0.6;
        repeat_delay = 200;
        repeat_rate = 80;

      };
	  "plugin:hyprscrolling" = {
		enabled = false;
		column_width = 0.40;
	  };
	  "plugin:scroller" = {
		column_default_width = "threeeighths";
	  };
	  # "plugin:hyprfocus" = {
		# enabled = false;
		# mode = "bounce"; # slide bounce
		# bounce_strength = 0.80;
		# slide_height = 40;
	  # };
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
			shrink_percentage = 0.85;
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
