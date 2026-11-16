{ inputs, config, lib, ... }:
{
	imports = [
		inputs.zen-browser.homeModules.default
	];
	programs.zen-browser = {
		enable = true;
		# Zen 仍在使用旧目录 ~/.zen（HM 默认写 ~/.config/zen，浏览器从不读取）
		configPath = "${config.home.homeDirectory}/.zen";
		profiles.default = {
			path = "940l4ih1.default";
			# iNiR 每次换壁纸都会重写 user.js；HM 会把它变成只读 store 软链，
			# iNiR 检测到软链就跳过（45-firefox.sh），颜色会失效。
			# 清空 settings 让 HM 不生成 user.js；Sine 的受管 mod 自带 no-updates，
			# 不依赖 sine.engine.auto-update=false。
			settings = lib.mkForce { };
			# 下面 CSS 顶格写：Nix 缩进字符串只剥离空格缩进（tab 不算），
			# 顶格可保证生成内容与原来的 userChrome.css 一致（HM 会多补一个
			# 末尾换行，对 CSS 无影响）。
			userChrome = ''
@namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");

/* 移除所有弹出面板的阴影、圆角外扩和透明边距 */
menupopup,
panel,
.panel-arrowcontent,
.menupopup-arrowscrollbox,
#appMenu-popup,
#context-navigation,
.context-menu {
  --panel-shadow: none !important;
  box-shadow: none !important;
  padding: 0 !important;
  margin: 0 !important;
  border: none !important;
  background: var(--arrowpanel-background) !important;
}

/* 修复右键菜单项额外留白 */
.menuitem-iconic,
.menu-right,
.menu-accel {
  padding: 2px 6px !important;
}

/* 强制面板紧贴内容边界 */
panelview,
.panel-header,
.panel-footer {
  margin: 0 !important;
  padding: 0 !important;
}

menupopup,
panel,
.panel-arrowcontent,
.menupopup-arrowscrollbox,
#appMenu-popup,
#context-navigation,
.context-menu {
  /* 统一圆角值（建议 8~12px，匹配 niri blur 半径） */
  border-radius: 10px !important;

  /* 关键：裁剪超出圆角的内容/背景 */
  overflow: hidden !important;

  /* 进阶：用 clip-path 确保 100% 物理裁剪（兼容性更好） */
  clip-path: inset(0 round 10px) !important;

  /* 防止 Firefox 原生渲染覆盖圆角 */
  -moz-appearance: none !important;

  /* 可选：如果角落仍有 1px 漏色，加 1px 透明边框"撑开"渲染层 */
  outline: 1px solid transparent !important;
}

/* 特殊处理：带箭头的面板（如 #appMenu-popup） */
.panel-arrowcontent {
  /* 箭头部分保持直角，只圆角主体 */
  border-radius: 10px !important;
  clip-path: inset(0 round 10px) !important;
}

/* 如果 niri 的 blur 半径是 12px，可单独覆盖 */
@media (-moz-bool-pref: "niri.blur.radius.12px") {
  /* 伪条件，仅作示例 */
  menupopup,
  panel,
  .panel-arrowcontent {
    border-radius: 12px !important;
    clip-path: inset(0 round 12px) !important;
  }
}

@media (-moz-bool-pref: "zen.view.sidebar-expanded") {
  #navigator-toolbox {
    --zen-native-inner-radius: 15px !important; /* 直接修改变量 */
  }
  /* 强制 .zen-toolbar-background 继承该变量 */
  #navigator-toolbox .zen-toolbar-background {
    border-radius: calc(var(--zen-native-inner-radius)) !important;
  }
}
'';
			sine = {
				enable = true;
				# 全部走 Sine：Sine 商店里没有的 ID 会自动回退到 Zen theme store
				mods = [
					"f4866f39-cfd6-4498-ab92-54213b8279dc" # Animations Plus
					"4a222d82-2803-4ed2-a390-90abfce4f195" # Back Fwd Always Hidden
					# "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
					"72f8f48d-86b9-4487-acea-eb4977b18f21" # Better CtrlTab Panel
					"a6335949-4465-4b71-926c-4a52d34bc9c0" # Better find bar
					"f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better unloaded tabs
					"a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaned url bar
					"5941aefd-67b0-453d-9b62-9071a31cbb0d" # Smaller Compact Mode
					# "e51b85e6-cef5-45d4-9fff-6986637974e1" # smaller zen toast popup
					"642854b5-88b4-4c40-b256-e035532109df" # Transparent Zen
					"20e8cc78-3dac-4db0-81a4-814672fb50af" # Left Side Glance Buttons
					"Neo-Zen"
				];
			};
		};
	};
}
