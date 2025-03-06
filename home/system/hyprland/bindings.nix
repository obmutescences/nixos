{ pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    bind = [
		"$mod,RETURN, exec, ${pkgs.kitty}/bin/kitty" # Kitty
		"$mod,E, exec, ${pkgs.xfce.thunar}/bin/thunar" # Thunar
		"$mod,F, exec, zen" # Qutebrowser
		"$mod,L, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock
		"$mod,X, exec, powermenu" # Powermenu
		"$mod,SPACE, exec, menu" # Launcher
		"$mod,C, exec, quickmenu" # Quickmenu
		"$shiftMod,SPACE, exec, hyprfocus-toggle" # Toggle HyprFocus
		# "$mod,TAB, overview:toggle" # Overview

		"$mod,Q, killactive," # Close window
		"$ALT,T, togglefloating," # Toggle Floating
		"$mod,W, exec, hyprctl dispatch fullscreen 1" # Toggle Fullscreen
		"$mod,V, scroller:fitsize, active"
		"$mod,left, movefocus, l" # Move focus left
		"$mod,right, movefocus, r" # Move focus Right
		"$mod,up, movefocus, u" # Move focus Up
		"$mod,down, movefocus, d" # Move focus Down

		# "$mod,PRINT, exec, screenshot region" # Screenshot region
		# ",PRINT, exec, screenshot monitor" # Screenshot monitor
		"$shiftMod,PRINT, exec, screenshot window" # Screenshot window
		# "$mod, P ,exec, screenshot region swappy" # Screenshot region then edit
		"$mod, P, exec, flameshot gui -r | wl-copy -t image/png"
		"$mod CTRL, P, exec, flameshot gui"

		"$shiftMod,T, exec, hyprpanel-toggle" # Toggle hyprpanel
		"$shiftMod,S, exec, ${pkgs.qutebrowser}/bin/qutebrowser :open $(wofi --show dmenu -L 1 -p ' Search on internet')" # Search on internet with wofi
		"$shiftMod,C, exec, clipboard" # Clipboard picker with wofi
		"$shiftMod,E, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji" # Emoji picker with wofi
		"$mod,F2, exec, night-shift" # Toggle night shift
		"$mod,F3, exec, night-shift" # Toggle night shift
		"$mod, home, scroller:movefocus, begin"
		"$mod, end, scroller:movefocus, end"
		"ALT, Tab, movefocus, r"
		"ALT, C, scroller:alignwindow, c"
		"ALT, F, togglefloating"
		"$mod, N, exec, ${pkgs.neovide}/bin/neovide"

		# wallpapers
		"$mod ALT, right, exec, next-wallpaper"
		"$mod ALT, left, exec, prev-wallpaper"

		"$mod, bracketleft, scroller:setmode, row"
		"$mod, bracketright, scroller:setmode, col"

		"$mod SHIFT, right, resizeactive, 100 0"
		"$mod SHIFT, left, resizeactive, -100 0"
		"$mod SHIFT, up, resizeactive, 0 -100"
		"$mod SHIFT, down, resizeactive, 0 100"

		"$mod SHIFT, 1, movetoworkspace, 1"
		"$mod SHIFT, 2, movetoworkspace, 2"
		"$mod SHIFT, 3, movetoworkspace, 3"
		"$mod SHIFT, 4, movetoworkspace, 4"
		"$mod SHIFT, 5, movetoworkspace, 5"
		"$mod SHIFT, 6, movetoworkspace, 6"
		"$mod SHIFT, 7, movetoworkspace, 7"
		"$mod SHIFT, 8, movetoworkspace, 8"
		"$mod SHIFT, 9, movetoworkspace, 9"
		"$mod SHIFT, 0, movetoworkspace, 10"
    ] ++ (builtins.concatLists (builtins.genList (i:
      let ws = i + 1;
      in [
        "$ctrl,code:1${toString i}, workspace, ${toString ws}"
        "$mod SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
      ]) 9));

    bindm = [
      "$mod,mouse:272, movewindow" # Move Window (mouse)
      "$mod,R, resizewindow" # Resize Window (mouse)
    ];

    bindl = [
      ",XF86AudioMute, exec, sound-toggle" # Toggle Mute
      ",XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause" # Play/Pause Song
      ",XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next" # Next Song
      ",XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous" # Previous Song
      ",switch:Lid Switch, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock when closing Lid
    ];

    bindle = [
      ",XF86AudioRaiseVolume, exec, sound-up" # Sound Up
      ",XF86AudioLowerVolume, exec, sound-down" # Sound Down
      ",XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
      ",XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
    ];

  };
}
