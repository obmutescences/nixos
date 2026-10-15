{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.clipferry;
in
{
  options.programs.clipferry = {
    enable = lib.mkEnableOption "clipferry X11 ↔ Wayland 剪贴板桥（systemd user service 随图形会话自启）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "clipferry 可执行文件（预编译二进制，见 home/programs/clipferry/clipferry）。";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--sync-mode"
        "eager"
      ];
      description = ''
        附加给 clipferry 的参数，常用：--sync-mode lazy|eager、--primary、
        --skip-sensitive、--aggressive-claims、--log-level debug、--no-landlock。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.clipferry = {
      Unit = {
        Description = "clipferry — X11 <-> Wayland clipboard bridge";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        # 崩溃只退避重试，不进入 failed 永久放弃状态。
        StartLimitIntervalSec = 0;
      };

      Service = {
        Type = "simple";
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/clipferry" ] ++ cfg.extraArgs
        );
        Restart = "always";
        RestartSec = 1;
        RestartSteps = 5;
        RestartMaxDelaySec = 30;

        # 只需要两个显示 socket（$WAYLAND_DISPLAY / $DISPLAY）与 stderr。
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = "AF_UNIX";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
