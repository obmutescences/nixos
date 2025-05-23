# Hyprpanel is the bar on top of the screen
# Display informations like workspaces, battery, wifi, ...
{ inputs, config, ... }:
let
  transparentButtons = config.var.theme.bar.transparentButtons;

  accent-alt = "#859289";
  accent = "#E67E80";
  background = "#414141";
  background-alt = "#2d353b";
  foreground = "#A0D683";
  font = config.var.theme.font;
  fontSize = "12";

  rounding = config.var.theme.rounding;
  border-size = config.var.theme.border-size;

  gaps-out = config.var.theme.gaps-out;
  gaps-in = config.var.theme.gaps-in;

  floating = config.var.theme.bar.floating;
  transparent = config.var.theme.bar.transparent;
  position = config.var.theme.bar.position;

  location = config.var.location;
in {

  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

  programs.hyprpanel = {
    enable = true;
    hyprland.enable = true;
    overwrite.enable = true;
    overlay.enable = true;
	settings = {
		layout = {
		  "bar.layouts" = {
			"0" = {
			  "left" = [ "dashboard" "storage" "cpu" "ram" "windowtitle" "media" ];
			  "middle" = [ "clock" ];
			  "right" = [
				"netstat"
				"systray"
				"volume"
				"bluetooth"
				"network"
				"notifications"
			  ];
			};
		  };
		};
	};

    override = {
      "theme.font.name" = "${font}";
      "theme.font.size" = "${fontSize}px";
      "theme.bar.buttons.monochrome" = true; # global color
	  "theme.bar.buttons.background" = "${background}";
      "theme.bar.outer_spacing" =
        "${if floating && transparent then "0" else "8"}px";
      "theme.bar.buttons.y_margins" =
        "${if floating && transparent then "0" else "8"}px";
      "theme.bar.buttons.spacing" = "0.3em";
      "theme.bar.buttons.radius" = "${
          if transparent then toString rounding else toString (rounding - 8)
        }px";
      "theme.bar.floating" = "${if floating then "true" else "false"}";
      "theme.bar.buttons.padding_x" = "0.8rem";
      "theme.bar.buttons.padding_y" = "0.4rem";
      "theme.bar.buttons.workspaces.hover" = "${accent-alt}";
      "theme.bar.buttons.workspaces.active" = "${accent}";
      "theme.bar.buttons.workspaces.available" = "${accent-alt}";
      "theme.bar.buttons.workspaces.occupied" = "${accent-alt}";
      "theme.bar.margin_top" =
        "${if position == "top" then toString (gaps-in * 2) else "0"}px";
      "theme.bar.margin_bottom" =
        "${if position == "top" then "0" else toString (gaps-in * 2)}px";
      "theme.bar.margin_sides" = "${toString gaps-out}px";
      "theme.bar.border_radius" = "${toString rounding}px";
	  "theme.bar.transparent" = true;
	  "theme.bar.opacity" = 100;
	  "theme.bar.buttons.opacity" = 90;
	  "theme.bar.buttons.background_opacity" = 45;
	  "theme.bar.buttons.background_hover_opacity" = 75;
	  "theme.bar.shadow" = "0px 0px 0px 0px #16161e";
	  "theme.bar.menus.opacity" = 90;
      "bar.launcher.icon" = "";
      "bar.workspaces.show_numbered" = false;
      "bar.workspaces.workspaces" = 5;
      "bar.workspaces.hideUnoccupied" = false;
      "bar.windowtitle.label" = true;
      "bar.volume.label" = false;
      "bar.network.truncation_size" = 12;
      "bar.bluetooth.label" = false;
      "bar.clock.format" = "%m-%d %H:%M %A";
      "bar.notifications.show_total" = true;
      "theme.notification.border_radius" = "${toString rounding}px";
      "theme.osd.enable" = true;
      "theme.osd.orientation" = "vertical";
      "theme.osd.location" = "left";
      "theme.osd.radius" = "${toString rounding}px";
      "theme.osd.margins" = "0px 0px 0px 10px";
      "theme.osd.muted_zero" = true;
      "menus.clock.weather.location" = "${location}";
      "menus.clock.weather.unit" = "metric";
      "menus.dashboard.powermenu.confirmation" = false;
	  "menus.transition" = "crossfade";

      "menus.dashboard.shortcuts.left.shortcut1.icon" = "";
      "menus.dashboard.shortcuts.left.shortcut1.command" = "zen";
      "menus.dashboard.shortcuts.left.shortcut1.tooltip" = "Zen";
      "menus.dashboard.shortcuts.left.shortcut2.icon" = "󰅶";
      "menus.dashboard.shortcuts.left.shortcut2.command" = "caffeine";
      "menus.dashboard.shortcuts.left.shortcut2.tooltip" = "Caffeine";
      "menus.dashboard.shortcuts.left.shortcut3.icon" = "󰖔";
      "menus.dashboard.shortcuts.left.shortcut3.command" = "night-shift";
      "menus.dashboard.shortcuts.left.shortcut3.tooltip" = "Night-shift";
      "menus.dashboard.shortcuts.left.shortcut4.icon" = "";
      "menus.dashboard.shortcuts.left.shortcut4.command" = "menu";
      "menus.dashboard.shortcuts.left.shortcut4.tooltip" = "Search Apps";
      "menus.dashboard.shortcuts.right.shortcut1.icon" = "";
      "menus.dashboard.shortcuts.right.shortcut1.command" = "hyprpicker -a";
      "menus.dashboard.shortcuts.right.shortcut1.tooltip" = "Color Picker";
      "menus.dashboard.shortcuts.right.shortcut3.icon" = "󰄀";
      "menus.dashboard.shortcuts.right.shortcut3.command" =
        "screenshot region swappy";
      "menus.dashboard.shortcuts.right.shortcut3.tooltip" = "Screenshot";

      "theme.bar.menus.monochrome" = false;
      "wallpaper.enable" = false;
      "theme.bar.menus.background" = "${background}";
      "theme.bar.menus.cards" = "${background-alt}";
      "theme.bar.menus.card_radius" = "${toString rounding}px";
      "theme.bar.menus.label" = "${foreground}";
      "theme.bar.menus.text" = "${foreground}";
      "theme.bar.menus.border.size" = "${toString border-size}px";
      "theme.bar.menus.border.color" = "${accent}";
      "theme.bar.menus.border.radius" = "${toString rounding}px";
      "theme.bar.menus.popover.text" = "${foreground}";
      "theme.bar.menus.popover.background" = "${background-alt}";
      "theme.bar.menus.listitems.active" = "${accent}";
      "theme.bar.menus.icons.active" = "${accent}";
      "theme.bar.menus.switch.enabled" = "${accent}";
      "theme.bar.menus.check_radio_button.active" = "${accent}";
      "theme.bar.menus.buttons.default" = "${accent}";
      "theme.bar.menus.buttons.active" = "${accent}";
      "theme.bar.menus.iconbuttons.active" = "${accent}";
      "theme.bar.menus.progressbar.foreground" = "${accent}";
      "theme.bar.menus.slider.primary" = "${accent}";
      "theme.bar.menus.tooltip.background" = "${background-alt}";
      "theme.bar.menus.tooltip.text" = "${foreground}";
      "theme.bar.menus.dropdownmenu.background" = "${background-alt}";
      "theme.bar.menus.dropdownmenu.text" = "${foreground}";
      "theme.bar.background" = "${background
        + (if transparentButtons && transparent then "00" else "")}";
	  # "theme.bar.background" = "transparent";
      "theme.bar.buttons.style" = "default";
      "theme.bar.buttons.text" = "${foreground}";
      # "theme.bar.buttons.background" =
      #   "${(if transparent then background else background-alt)
      #   + (if transparentButtons then "00" else "")}";
      "theme.bar.buttons.icon" = "${accent}";
      "theme.bar.buttons.notifications.background" = "${background-alt}";
      "theme.bar.buttons.hover" = "${background}";
      "theme.bar.buttons.notifications.hover" = "${background}";
      "theme.bar.buttons.notifications.total" = "${accent}";
      "theme.bar.buttons.notifications.icon" = "${accent}";
      "theme.notification.background" = "${background-alt}";
      "theme.notification.actions.background" = "${accent}";
      "theme.notification.actions.text" = "${foreground}";
      "theme.notification.label" = "${accent}";
      "theme.notification.border" = "${background-alt}";
      "theme.notification.text" = "${foreground}";
      "theme.notification.labelicon" = "${accent}";
      "theme.osd.bar_color" = "${accent}";
      "theme.osd.bar_overflow_color" = "${accent-alt}";
      "theme.osd.icon" = "${background}";
      "theme.osd.icon_container" = "${accent}";
      "theme.osd.label" = "${accent}";
      "theme.osd.bar_container" = "${background-alt}";
      "theme.bar.menus.menu.media.background.color" = "${background-alt}";
      "theme.bar.menus.menu.media.card.color" = "${background-alt}";
      "theme.bar.menus.menu.media.card.tint" = 90;
      "bar.customModules.updates.pollingInterval" = 1440000;
      "bar.media.show_active_only" = true;
      "theme.bar.location" = "${position}";
      "bar.workspaces.numbered_active_indicator" = "color";
      "bar.workspaces.monitorSpecific" = false;
      "bar.workspaces.applicationIconEmptyWorkspace" = "";
      "bar.workspaces.showApplicationIcons" = true;
      "bar.workspaces.showWsIcons" = true;
      "theme.bar.dropdownGap" = "4.5em";
	  "theme.bar.buttons.clock.text" = "#b23a48";
	  "theme.bar.buttons.clock.icon" = "#b23a48";
    };
  };
}
