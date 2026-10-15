{
  lib,
  stdenv,
  patchelf,
  python3,
  zlib,
}:

# wechat_notify.py 用 PyInstaller 打成单文件二进制（Python 3.13 + dbus-next 全部内嵌）。
# 与 ~/Downloads/download_ks/flake.nix 的 wechat-tray-notifier-bin 一致，
# 额外用 patchelf 把 bootloader 的 interpreter/RPATH 指到 store 里的 glibc/zlib，
# 这样不依赖 nix-ld 也能跑。
let
  python = python3.withPackages (ps: [
    ps.pyinstaller
    ps.dbus-next
  ]);
in
stdenv.mkDerivation {
  pname = "wechat-tray-notifier";
  version = "0.2.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    python
    patchelf
  ];

  buildInputs = [ zlib ];

  buildPhase = ''
    runHook preBuild

    export PYINSTALLER_CONFIG_DIR="$TMPDIR/pyinstaller"
    pyinstaller \
      --clean \
      --noconfirm \
      --onefile \
      --noupx \
      --name wechat-tray-notifier \
      wechat_notify.py

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/wechat-tray-notifier $out/bin/wechat-tray-notifier

    patchelf \
      --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
      --set-rpath ${lib.makeLibraryPath [ zlib stdenv.cc.libc ]} \
      $out/bin/wechat-tray-notifier

    runHook postInstall
  '';

  meta = {
    description = "Send desktop notifications when WeChat's StatusNotifierItem blinks (PyInstaller single-file build)";
    mainProgram = "wechat-tray-notifier";
    platforms = lib.platforms.linux;
  };
}
