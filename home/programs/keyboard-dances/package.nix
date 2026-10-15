{
  lib,
  rustPlatform,
  pkg-config,
  alsa-lib,
  libinput,
  systemd,

  # keyboard_dances 仓库 nix_cli 分支的源码（flake input，见 ~/.config/nixos/flake.nix）。
  # 该分支已提交 Cargo.lock：git 类 flake input 只带 git 跟踪的文件。
  src,
}:

rustPlatform.buildRustPackage {
  pname = "keyboard-dances";
  version = (lib.importTOML (src + "/Cargo.toml")).package.version;

  inherit src;
  cargoLock.lockFile = src + "/Cargo.lock";

  nativeBuildInputs = [ pkg-config ];

  # alsa-lib: rodio/cpal 音频输出；libinput + systemd(udev): 输入设备监听
  buildInputs = [
    alsa-lib
    libinput
    systemd
  ];

  doCheck = false;

  meta = {
    description = "Play a sound on every keyboard press and release (libinput/Wayland)";
    mainProgram = "keyboard_dances";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
