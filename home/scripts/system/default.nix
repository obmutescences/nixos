# - ## System
#- 
#- Usefull quick scripts
#-
#- - `menu` - Open wofi with drun mode. (wofi)
#- - `powermenu` - Open power dropdown menu. (wofi)
#- - `lock` - Lock the screen. (hyprlock)
{ pkgs, ... }:

let
  menu = pkgs.writeShellScriptBin "menu"
    # bash
    ''
      if pgrep wofi; then
      	pkill wofi
      else
      	wofi -p " Apps" --show drun
      fi
      # if pgrep tofi; then
      # 	pkill tofi
      # else
      # 	tofi-drun --drun-launch=true
      # fi
    '';

  powermenu = pkgs.writeShellScriptBin "powermenu"
    # bash
    ''
      if pgrep wofi; then
      	pkill wofi
      # if pgrep tofi; then
      #   pkill tofi
      else
        options=(
          "󰌾 Lock"
          "󰍃 Logout"
          " Suspend"
          "󰑐 Reboot"
          "󰿅 Shutdown"
        )

        selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Powermenu" --dmenu)
        # selected=$(printf '%s\n' "''${options[@]}" | tofi --prompt-text "> ")
        selected=''${selected:2}

        case $selected in
          "Lock")
            ${pkgs.hyprlock}/bin/hyprlock
            ;;
          "Logout")
            hyprctl dispatch exit
            ;;
          "Suspend")
            systemctl suspend
            ;;
          "Reboot")
            systemctl reboot
            ;;
          "Shutdown")
            systemctl poweroff
            ;;
        esac
      fi
    '';

  quickmenu = pkgs.writeShellScriptBin "quickmenu"
    # bash
    ''
      if pgrep wofi; then
      	pkill wofi
      # if pgrep tofi; then
      #   pkill tofi
      else
        options=(
          "󰅶 Caffeine"
          "󰖔 Night-shift"
          " Nixy"
          "󰈊 Hyprpicker"
          "󰸉 Next-Wallpaper"
        )

        selected=$(printf '%s\n' "''${options[@]}" | wofi -p " Quickmenu" --dmenu)
        # selected=$(printf '%s\n' "''${options[@]}" | tofi --prompt-text "> ")
        selected=''${selected:2}

        case $selected in
          "Caffeine")
            caffeine
            ;;
          "Night-shift")
            night-shift
            ;;
          "Nixy")
            kitty zsh -c nixy
            ;;
          "Hyprpicker")
            sleep 0.2 && ${pkgs.hyprpicker}/bin/hyprpicker -a
            ;;
          "Next-Wallpaper")
            next-wallpaper
            ;;
        esac
      fi
    '';

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${pkgs.hyprlock}/bin/hyprlock
    '';
   
  start-neovide = pkgs.writeShellScriptBin "start-neovide"
    # bash
    ''
	source ~/.zshrc
	exec /home/zerone/projects/neovide/target/release/neovide
    '';
  keybord-sound = pkgs.writeShellScriptBin "keybord-sound"
    # bash
    ''
	/home/zerone/Downloads/bucklespring/buckle -p ~/.config/nixos/home/sources/keybord-sound/alpacas -g 100 -s 100
    '';
  screenshot-pin = pkgs.writeShellScriptBin "screenshot-pin"
    # bash
    ''
	flameshot gui -r | wl-copy -t image/png
    '';

in { home.packages = [ menu powermenu lock quickmenu start-neovide keybord-sound screenshot-pin ]; }
