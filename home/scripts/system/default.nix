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

  lock = pkgs.writeShellScriptBin "lock"
    # bash
    ''
      ${pkgs.hyprlock}/bin/hyprlock
    '';
   
  start-neovide = pkgs.writeShellScriptBin "start-neovide"
    # bash
    ''
	source ~/.zshrc
	exec /home/zerone/.cache/target/release/neovide
    '';
  keyboard-sound-alpacas = pkgs.writeShellScriptBin "keyboard-sound-alpacas"
    # bash
    ''
	buckle -p ~/.config/nixos/home/sources/keybord-sound/alpacas -g 100 -s 100
    '';
  keyboard-sound-nkcream = pkgs.writeShellScriptBin "keyboard-sound-nkcream"
    # bash
    ''
	buckle -p ~/.config/nixos/home/sources/keybord-sound/nk-cream -g 100 -s 100
    '';
  screenshot-pin = pkgs.writeShellScriptBin "screenshot-pin"
    # bash
    ''
	flameshot gui -r | wl-copy -t image/png
    '';
  aicommits-en = pkgs.writeShellScriptBin "aicommits-en"
	# bash
	''
	aicommits -p "固定格式：:icon: type: message. 强制规则：1. :icon:：根据代码变更性质自动匹配标准 Emoji 短码（如 :sparkles: :bug: :memo: :art: :recycle: :zap: :white_check_mark: :rocket: :wrench: :rewind:）。2. type：必 须为全小写英文，且严格根据代码内容从以下列表中单选最匹配的一项：feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. 3. message：精准概括本次变更的核心目的。使用祈使句，末尾无标点。内容语言固定为英文. 4. 输出限制：仅输出符合上述格式的纯文本单行结果。严禁使用 Markdown 代码块、引号、前后缀、换行或任何分析解释。 示例：:sparkles: feat: add kuaishou campaign module, :bug: fix: prevent duplicate submission on weak network"
	'';
  aicommits-cn = pkgs.writeShellScriptBin "aicommits-cn"
	# bash
	''
	aicommits -p "固定格式：:icon: type: message. 强制规则：1. :icon:：根据代码变更性质自动匹配标准 Emoji 短码（如 :sparkles: :bug: :memo: :art: :recycle: :zap: :white_check_mark: :rocket: :wrench: :rewind:）。2. type：必 须为全小写英文，且严格根据代码内容从以下列表中单选最匹配的一项：feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. 3. message：精准概括本次变更的核心目的。使用祈使句，末尾无标点。内容语言固定为中文. 4. 输出限制：仅输出符合上述格式的纯文本单行结果。严禁使用 Markdown 代码块、引号、前后缀、换行或任何分析解释。 示例：:sparkles: feat: add kuaishou campaign module, :bug: fix: prevent duplicate submission on weak network"
	'';

in { home.packages = [ menu powermenu lock start-neovide keyboard-sound-alpacas keyboard-sound-nkcream screenshot-pin aicommits-en aicommits-cn]; }
