{ config, pkgs, inputs, lib, ... }:

let
  # 定义自定义 QuickShell 包（基于你的扩展列表）
  myQuickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.withModules [
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
	  pkgs.kdePackages.kirigami
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
			  pkgs.kdePackages.kirigami
			  pkgs.kdePackages.kdialog
			
			# KDE components for bluetooth and network management
			pkgs.kdePackages.kcmutils  # Provides kcmshell6
			pkgs.kdePackages.kde-cli-tools  # KDE CLI tools
			pkgs.kdePackages.bluez-qt  # Bluetooth QML module
			pkgs.kdePackages.bluedevil  # KDE bluetooth manager
			pkgs.kdePackages.plasma-nm  # KDE network manager
			pkgs.kdePackages.networkmanager-qt  # NetworkManager QML bindings
			pkgs.kdePackages.modemmanager-qt  # ModemManager QML bindings
			pkgs.kdePackages.kconfig  # KDE config module
			pkgs.kdePackages.kcoreaddons  # KDE core addons
			pkgs.kdePackages.ki18n  # KDE internationalization
            ]}"
        fi
      done
    '';
  };
in
{
  # 添加到系统包（或 home.packages，如果是 home-manager 模块）
  environment.systemPackages = with pkgs; [
	kdePackages.qtbase
	kdePackages.qt6ct
	kdePackages.qtpositioning
	kdePackages.qt5compat
	kdePackages.qtwayland
	kdePackages.qtlocation
	kdePackages.qtutilities
	kdePackages.qtdeclarative
	kdePackages.qtimageformats # WEBP and other image formats
	kdePackages.qtmultimedia   # Media playback
	kdePackages.qtquicktimeline
	kdePackages.qtsensors
	kdePackages.qtsvg          # SVG image support
	kdePackages.qttools
	kdePackages.qttranslations
	kdePackages.qtvirtualkeyboard
	kdePackages.qtwebsockets
	kdePackages.syntax-highlighting
	kdePackages.kirigami
	kdePackages.kirigami.unwrapped
    kdePackages.kdialog
    kdePackages.qtpositioning  # For Weather service location features
    
    # KDE components for bluetooth and network management
    kdePackages.kcmutils  # Provides kcmshell6
    kdePackages.kde-cli-tools  # KDE CLI tools
    kdePackages.bluez-qt  # Bluetooth QML module
    kdePackages.bluedevil  # KDE bluetooth manager
    kdePackages.plasma-nm  # KDE network manager
    kdePackages.networkmanager-qt  # NetworkManager QML bindings
    kdePackages.modemmanager-qt  # ModemManager QML bindings
    kdePackages.kconfig  # KDE config module
    kdePackages.kcoreaddons  # KDE core addons
    kdePackages.ki18n  # KDE internationalization
	qt6.qt5compat       # 或 kdePackages.qt5compat
	libsForQt5.qt5.qtgraphicaleffects
    wrappedQuickshell  # 使用 wrapped 版本以确保环境正确
    # 如果不需要 wrapping，直接用 myQuickshell
  ];

  # 如果你有 PythonEnv 或其他自定义，添加到这里
}
