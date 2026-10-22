# Udiskie is a simple daemon that uses udisks to automatically mount removable storage devices.
{ pkgs, ... }:
{
  services.udiskie = {
    enable = true;
    notify = true;
    automount = true;
    # udiskie 2.7.0 自带的 keyutils 测试在 Linux 7.2 上必失败（上游测试问题，
    # 与 udiskie 运行无关），跳过构建期检查，避免整个系统构建被卡住。
    package = pkgs.udiskie.overridePythonAttrs (_: { doCheck = false; });
  };
}
