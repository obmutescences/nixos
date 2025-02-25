{ pkgs, ... }:
{
  # 具体配置
  services.dae = {
    enable = true;
	disableTxChecksumIpGeneric = false;
    # configFile = "/etc/dae/config.dae";
    # 其他参数...
	config = builtins.readFile ./config1.dae;
    assets = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
  };
}
