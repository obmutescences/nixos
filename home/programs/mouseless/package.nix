{
  lib,
  stdenvNoCC,
  patchelf,
  glibc,
}:

# mouseless 0.3.0 预编译二进制 + 配置（放在 home/programs/ 下是为了跟其它自管程序放一起；
# 实际由 nixos/programs.nix 的 systemd.services.mouseless 以 root 运行，不是 home-manager 模块）。
# 二进制原始 interp 是 /lib64/ld-linux-x86-64.so.2（靠 nix-ld），这里显式声明 glibc 依赖并
# 重写 interpreter/RUNPATH，保证闭包里有记录、不被 GC 掉。
stdenvNoCC.mkDerivation {
  pname = "mouseless";
  version = "0.3.0";

  src = lib.cleanSource ./.;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ patchelf ];
  buildInputs = [ glibc ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src/mouseless $out/bin/mouseless
    install -Dm644 $src/config.yaml $out/share/mouseless/config.yaml

    patchelf \
      --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 \
      --set-rpath ${lib.makeLibraryPath [ glibc ]} \
      $out/bin/mouseless

    runHook postInstall
  '';

  meta = {
    description = "Keyboard-driven mouse for Wayland (reads evdev, emits uinput events)";
    homepage = "https://github.com/jbensmann/mouseless";
    mainProgram = "mouseless";
    platforms = lib.platforms.linux;
  };
}
