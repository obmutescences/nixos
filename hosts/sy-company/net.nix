{
	networking.dhcpcd.enable = false;
	networking.useDHCP = false;
	networking.interfaces.enp37s0 = {
	  ipv4.addresses = [{
		address = "192.168.10.10";  # 设置静态 IP 地址
		prefixLength = 24;          # 子网掩码 (通常是 24 位)
	  }];
	  # ipv4.gateway = "192.168.10.1";  # 默认网关
	  # 如果有 DNS 配置需求，设置 DNS 服务器
	  # ipv4.dns = [ "8.8.8.8" "1.1.1.1" ];
	};
	networking.defaultGateway  = "192.168.10.1";
	networking.nameservers  = [ "8.8.8.8" "1.1.1.1" ];
}
