{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.programs.keyboard-dances;

  # sounds/<配置名>/{press,release}.{wav,ogg}：文件名固定，目录名即配置名。
  soundsDir = ./sounds;

  soundFile =
    dir: base:
    let
      found = builtins.filter builtins.pathExists (
        map (ext: dir + "/${base}.${ext}") [
          "wav"
          "ogg"
        ]
      );
    in
    if found == [ ] then
      throw "programs.keyboard-dances: ${toString dir} 下缺少 ${base}.wav 或 ${base}.ogg"
    else
      builtins.head found;

  profileNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir soundsDir)
  );

  profileFor =
    name:
    let
      dir = soundsDir + "/${name}";
    in
    {
      press = soundFile dir "press";
      release = soundFile dir "release";
    };

  active = profileFor cfg.profile;
in
{
  options.programs.keyboard-dances = {
    enable = lib.mkEnableOption "keyboard-dances 按键音（user service 开机自启）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {
        src = inputs.keyboard-dances.outPath;
      };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { src = inputs.keyboard-dances.outPath; }";
      description = "keyboard-dances 可执行文件（源码来自 inputs.keyboard-dances 的 nix_cli 分支）。";
    };

    profile = lib.mkOption {
      type = lib.types.enum profileNames;
      default = "nk-cream";
      description = "启用 sounds/ 下的哪个配置（目录名）。可选：${lib.concatStringsSep ", " profileNames}。";
    };

    volume = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "按下音量（释放音量固定为其 20%）。";
    };

    sampleRate = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "采样率倍率，>1 音调更高、速度更快。";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.keyboard-dances = {
      Unit = {
        Description = "Keyboard Dances keyboard sound player";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " [
          "${cfg.package}/bin/keyboard_dances"
          (toString active.press)
          (toString active.release)
          "--volume"
          (toString cfg.volume)
          "--sample-rate"
          (toString cfg.sampleRate)
        ];
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
