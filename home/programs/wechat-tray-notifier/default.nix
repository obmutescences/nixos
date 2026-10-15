{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.wechat-tray-notifier;
in
{
  options.programs.wechat-tray-notifier = {
    enable = lib.mkEnableOption "wechat-tray-notifier 微信托盘闪烁通知（systemd user service 随图形会话自启）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "wechat-tray-notifier 可执行文件（wechat_notify.py 经 PyInstaller 打包）。";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--log-file" "%h/.cache/wechat-tray-notifier.log" ];
      description = ''
        传给 wechat-tray-notifier 的额外参数。默认写日志到 ~/.cache/wechat-tray-notifier.log；
        程序自身会重试连接 session bus（--connect-timeout 30）并等待微信托盘项出现，无需外部排序。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.wechat-tray-notifier = {
      Unit = {
        Description = "WeChat tray notifier (StatusNotifierItem 闪烁 → 桌面通知)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/wechat-tray-notifier" ] ++ cfg.extraArgs
        );
        # DBus 直发失败时会退到 notify-send，保证兜底路径可用。
        Environment = [ "PATH=${lib.makeBinPath [ pkgs.libnotify ]}" ];
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
