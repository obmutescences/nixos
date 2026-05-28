-- ================= 环境变量 =================
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("NIXOS_OZONE_WL", "1")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GDK_SCALE", "1")
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("BROWSER", "zen-beta")

-- ================= 基础配置 =================
hl.config({
	general = {
		resize_on_border = true,
		gaps_in = 5,
		gaps_out = 10,
		border_size = 2,
		layout = "scrolling",
		-- col = {
		-- 	active_border = "rgba(e67e80ff) rgba(dbbc7fff) 45deg",
		-- 	inactive_border = "rgba(1e8b50d9) rgba(50b050d9) 45deg",
		-- },
	},
	decoration = {
		rounding = 10,
		dim_inactive = true,
		dim_strength = 0.4,
		shadow = {
			enabled = false,
			-- color = "rgba(e67e80ff)",
			-- color_inactive = "rgba(62, 67, 46, 0.9)",
			range = 40,
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			popups = true,
			popups_ignorealpha = 0.5,
			input_methods = true,
			input_methods_ignorealpha = 0.5,
			special = true,
			vibrancy = 0.5,
			vibrancy_darkness = 0.7,
		},
	},
	animations = {
		enabled = true,
		bezier = {
			"default, 0.05, 0.9, 0.1, 1.05",
			"wind, 0.05, 0.9, 0.1, 1.05",
			"overshot, 0.13, 0.99, 0.29, 1.08",
			"liner, 1, 1, 1, 1",
			"easeOutCirc, 0, 0.55, 0.45, 1",
			"md3_decel, 0.05, 0.7, 0.1, 1",
			"md3_accel, 0.3, 0, 0.8, 0.15",
			"realsmooth, 0.28, 0.29, 0.69, 1.08",
		},
		animation = {
			"windows, 1, 8, md3_decel, popin 5%",
			"windowsIn, 1, 7, md3_decel, popin 5%",
			"windowsOut, 1, 10, md3_accel, popin 5%",
			"windowsMove, 5, 4, overshot, slide",
			"layers, 1, 7, default, popin",
			"fadeIn, 1, 7, overshot",
			"fadeOut, 1, 7, overshot",
			"fadeSwitch, 1, 7, default",
			"fadeShadow, 1, 7, default",
			"fadeDim, 1, 7, default",
			"fadeLayers, 1, 7, default",
			"workspaces, 1, 8, overshot, slidevert",
			"border, 1, 1, liner",
			"borderangle, 1, 30, liner, once",
		},
	},
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0.6,
		repeat_delay = 200,
		repeat_rate = 80,
	},
	gestures = {},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 0,
		force_default_wallpaper = 0,
	},
	scrolling = {
		column_width = 0.4,
		fullscreen_on_one_column = false,
	},
})

hl.on("config.reloaded", function()
	hl.config({
		plugin = {
			hyprfocus = {
				mode = "bounce",
				slide_height = 8,
				bounce_strength = 0.7,
				fade_opacity = 0.85,
			},
			-- hyprfocus = {
			-- 	enabled = true,
			-- 	keyboard_focus_animation = "shrink",
			-- 	mouse_focus_animation = "shrink",
			-- 	animate_floating = false,
			-- 	animate_workspacechange = true,
			-- 	focus_animation = "shrink",
			-- 	bezier = {
			-- 		"bezIn, 0.5, 0.0, 1.0, 0.5",
			-- 		"bezOut, 0.0, 0.5, 0.5, 1.0",
			-- 		"overshot, 0.05, 0.9, 0.1, 1.05",
			-- 		"smoothOut, 0.36, 0, 0.66, -0.56",
			-- 		"smoothIn, 0.25, 1, 0.5, 1",
			-- 		"realsmooth, 0.28, 0.29, 0.69, 1.08",
			-- 	},
			-- 	flash = {
			-- 		flash_opacity = 0.7,
			-- 		in_bezier = "realsmooth",
			-- 		in_speed = 0.5,
			-- 		out_bezier = "realsmooth",
			-- 		out_speed = 3,
			-- 	},
			-- 	shrink = {
			-- 		shrink_percentage = 0.85,
			-- 		in_bezier = "realsmooth",
			-- 		in_speed = 6.5,
			-- 		out_bezier = "realsmooth",
			-- 		out_speed = 6.0,
			-- 	},
			-- },
		},
	})
end)

-- ================= 显示器与外部来源 =================
hl.monitor({
	output = "DP-5",
	mode = "3840x2160@143.99",
	position = "auto",
	scale = 1.2,
})
hl.monitor({
	output = "DP-1",
	mode = "2560x1440@180.00",
	position = "auto",
	scale = 1,
})

require("dms/colors")
-- require("~/.config/hypr/dms/shadow.conf")

-- ================= 窗口规则 =================
hl.window_rule({ match = { class = ".*" }, opacity = 0.8 })
hl.window_rule({ match = { class = "^(neovide)$" }, opacity = "0.99 0.99" })
hl.window_rule({ match = { class = "^(firefox)$" }, opacity = "0.99 0.99" })
hl.window_rule({ match = { class = "^(wechat)$" }, opacity = "0.96 0.96" })

hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" }, float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Library)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(top)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(btop)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(htop)$" }, float = true })
hl.window_rule({ match = { class = "^(vlc)$" }, float = true })
hl.window_rule({ match = { class = "^(kvantummanager)$" }, float = true })
hl.window_rule({ match = { class = "^(qt5ct)$" }, float = true })
hl.window_rule({ match = { class = "^(qt6ct)$" }, float = true })
hl.window_rule({ match = { class = "^(nwg-look)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.ark)$" }, float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(.blueman-manager-wrapped)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-applet)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(flameshot-pin)$" }, float = true })
hl.window_rule({ match = { class = "^(flameshot-pin)$" }, pin = true })
hl.window_rule({ match = { class = "^(Alacritty)$" }, float = true })
hl.window_rule({ match = { class = "^(com.mitchellh.ghostty)$" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.kde)$" }, float = true })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.kde)$" }, size = "60% 65%" })

-- Picture in Picture 规则
local pip_regex = "^([Pp]icture[-s]?[Ii]n[-s]?[Pp]icture)(.*)$"
hl.window_rule({ match = { title = pip_regex }, float = true })
hl.window_rule({ match = { title = pip_regex }, move = "73% 72%" })
hl.window_rule({ match = { title = pip_regex }, size = { "monitor_w * 0.25", "monitor_h * 0.25" } })
hl.window_rule({ match = { title = pip_regex }, pin = true })

-- 其他特定规则
hl.window_rule({ match = { class = "^(QQ)$", title = "^(QQ)$" }, tile = true })
hl.window_rule({ match = { class = "^(wechat)$", title = "^(图片和视频)$" }, tile = true })
hl.window_rule({ match = { class = "^(wechat)$", title = "^(图片和视频)$" }, float = true })

-- ================= 层规则 =================
hl.layer_rule({ match = { namespace = "dms:bar" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true })

-- ================= 快捷键绑定 =================
-- 基础应用启动
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + F", hl.dsp.exec_cmd("zen-beta"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("powermenu"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("menu"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("quickmenu"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("start-neovide"))

-- 窗口管理
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("ALT + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + F", hl.dsp.window.float({ action = "toggle" }))
-- hl.bind("SUPER + W", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + W", hl.dsp.window.fullscreen_state({ internal = 1, client = 1, action = "toggle" }))

-- 焦点移动
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())

-- 截图与工具
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("screenshot window"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("sh -c 'flameshot gui -r | wl-copy -t image/png'"))
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("flameshot gui"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("clipboard"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("wl-kbptr"))

-- DMS 插件控制
hl.bind("SUPER + ALT + Right", hl.dsp.exec_cmd("dms ipc call wallpaper next"))
hl.bind("SUPER + ALT + Left", hl.dsp.exec_cmd("dms ipc call wallpaper prev"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("dms ipc call plugins toggle aiAssistant"))

-- 窗口调整大小
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x = 100, y = 0 }))
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.resize({ x = -100, y = 0 }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -100 }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 100 }))

-- 鼠标滚动模拟
hl.bind("SUPER + J", hl.dsp.exec_cmd("wlrctl pointer scroll 20 0"))
hl.bind("SUPER + U", hl.dsp.exec_cmd("wlrctl pointer scroll -20 0"))

-- 工作区切换与移动 (数字键)
for i = 1, 10 do
	local key = i % 10 -- 10 对应按键 0
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- 工作区切换与移动 (小键盘/代码键 code:10 - code:18)
for i = 0, 8 do
	local ws = i + 1
	hl.bind("CTRL + code:1" .. i, hl.dsp.focus({ workspace = ws }))
	hl.bind("SUPER + SHIFT + code:1" .. i, hl.dsp.window.move({ workspace = ws }))
end

-- 鼠标绑定 (bindm)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + R", hl.dsp.window.resize(), { mouse = true })

-- 媒体与系统控制 (bindl - locked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("sound-toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })

-- 媒体与系统控制 (bindle - locked + repeating)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("sound-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("sound-down"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightness-down"), { locked = true, repeating = true })

-- ================= 启动脚本 =================
hl.on("hyprland.start", function()
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adwaita-dark")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
	hl.exec_cmd("dbus-update-activation-environment --all")
	hl.exec_cmd("sh -c 'sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP'")
	hl.exec_cmd("fcitx5 -d --replace")
	hl.exec_cmd("FlClash")
	hl.exec_cmd("keybord-sound-nkcream")
end)
