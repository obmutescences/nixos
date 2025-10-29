{ config, pkgs, inputs, lib, ... }:

let
  # 定义自定义 QuickShell 包（基于你的扩展列表）
  myQuickshell = inputs.quickshell.packages.${pkgs.system}.quickshell.withModules [
	  pkgs.kdePackages.qtbase
	  pkgs.kdePackages.qt6ct
	  pkgs.kdePackages.qtpositioning
	  pkgs.kdePackages.qt5compat
	  pkgs.kdePackages.qtwayland
	  pkgs.kdePackages.qtlocation
	  pkgs.kdePackages.qtutilities
	  pkgs.kdePackages.qtdeclarative
	  pkgs.kdePackages.qtimageformats # WEBP and other image formats
	  pkgs.kdePackages.qtmultimedia   # Media playback
	  pkgs.kdePackages.qtquicktimeline
	  pkgs.kdePackages.qtsensors
	  pkgs.kdePackages.qtsvg          # SVG image support
	  pkgs.kdePackages.qttools
	  pkgs.kdePackages.qttranslations
	  pkgs.kdePackages.qtvirtualkeyboard
	  pkgs.kdePackages.qtwebsockets
	  pkgs.kdePackages.syntax-highlighting
  ];

  # 如果需要 wrapping（如第一段代码所示），可以在这里扩展
  wrappedQuickshell = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [ myQuickshell ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Wrap 二进制以添加 QML import paths
      for binary in quickshell qs; do
        if [ -f "$out/bin/$binary" ]; then
          wrapProgram "$out/bin/$binary" \
            --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath "lib/qt-6/qml" [
			  pkgs.kdePackages.qtbase
			  pkgs.kdePackages.qt6ct
			  pkgs.kdePackages.qtpositioning
			  pkgs.kdePackages.qt5compat
			  pkgs.kdePackages.qtwayland
			  pkgs.kdePackages.qtlocation
			  pkgs.kdePackages.qtutilities
			  pkgs.kdePackages.qtdeclarative
			  pkgs.kdePackages.qtimageformats # WEBP and other image formats
			  pkgs.kdePackages.qtmultimedia   # Media playback
			  pkgs.kdePackages.qtquicktimeline
			  pkgs.kdePackages.qtsensors
			  pkgs.kdePackages.qtsvg          # SVG image support
			  pkgs.kdePackages.qttools
			  pkgs.kdePackages.qttranslations
			  pkgs.kdePackages.qtvirtualkeyboard
			  pkgs.kdePackages.qtwebsockets
			  pkgs.kdePackages.syntax-highlighting
            ]}"
        fi
      done
    '';
  };
in
{
  # 添加到系统包（或 home.packages，如果是 home-manager 模块）
  environment.systemPackages = with pkgs; [
    wrappedQuickshell  # 使用 wrapped 版本以确保环境正确
    # 如果不需要 wrapping，直接用 myQuickshell
  ];

  # 如果你有 PythonEnv 或其他自定义，添加到这里
}
