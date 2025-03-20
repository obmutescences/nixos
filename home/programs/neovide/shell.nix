let
  rust_overlay = import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz");
  pkgs = import <nixpkgs> { overlays = [ rust_overlay ]; };
in
pkgs.mkShell {
  buildInputs = [
    (pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default))
    pkgs.fontconfig
    pkgs.freetype
	pkgs.pkg-config
    pkgs.wayland
	pkgs.libglvnd
    pkgs.libxkbcommon
  ];
  env = {
    RUSTFLAGS = "-C link-arg=-Wl,-rpath,${pkgs.lib.makeLibraryPath [
      pkgs.fontconfig
      pkgs.freetype
      pkgs.wayland
	  pkgs.libglvnd
	  pkgs.libxkbcommon
    ]}";
  };
}
