{
  lib,
  stdenvNoCC,
  patchelf,
  glibc,
  libgcc,
}:

# clipferry 0.0.3 预编译二进制（Rust / ELF64 PIE，1.0 MiB）。
# 二进制本体：./clipferry（与 ~/.local/bin/clipferry 同 sha256:
# 953fe14a2a3978a331b21812948b2ae205d374f6b70eb5a5d8962424c08243c7）。
# 它原本指向构建机的 glibc/gcc-lib；这里显式声明 glibc + libgcc 依赖并重写
# interpreter/RUNPATH，保证闭包里有记录、不被 GC 掉。
stdenvNoCC.mkDerivation {
  pname = "clipferry";
  version = "0.0.3";

  src = lib.cleanSource ./.;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ patchelf ];
  buildInputs = [
    glibc
    libgcc
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src/clipferry $out/bin/clipferry

    patchelf \
      --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 \
      --set-rpath ${lib.makeLibraryPath [ glibc libgcc ]} \
      $out/bin/clipferry

    runHook postInstall
  '';

  meta = {
    description = "X11 <-> Wayland clipboard bridge";
    homepage = "https://github.com/jmylchreest/clipferry";
    mainProgram = "clipferry";
    platforms = lib.platforms.linux;
  };
}
