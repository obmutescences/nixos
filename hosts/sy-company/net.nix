{
	networking.dhcpcd.enable = false;
	networking.useDHCP = false;
	# NetworkManager 默认会自己建一个 DHCP 连接来管这块网卡，导致重启/断网重连后
	# 又多拿一个动态 IP（网卡上出现两个地址）。让 NM 不管理它，只保留下面的静态 IP。
	networking.networkmanager.unmanaged = [ "interface-name:enp37s0" ];
	networking.interfaces.enp37s0 = {
	  ipv4.addresses = [{
		address = "192.168.1.100";  # 设置静态 IP 地址
		prefixLength = 24;          # 子网掩码 (通常是 24 位)
	  }];
	  # ipv4.gateway = "192.168.10.1";  # 默认网关
	  # 如果有 DNS 配置需求，设置 DNS 服务器
	  # ipv4.dns = [ "8.8.8.8" "1.1.1.1" ];
	};
	networking.defaultGateway  = "192.168.1.1";
	networking.nameservers  = [ "8.8.8.8" "1.1.1.1" ];
}
