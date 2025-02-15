{
  # 具体配置
  services.dae = {
    enable = true;
    openFirewall = {
        enable = false;
        port = 12345;
    };
    configFile = "/etc/dae/config.dae";
    # 其他参数...
  };
}
