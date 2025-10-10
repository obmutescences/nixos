{
  imports = [
    ../nixos/audio.nix
    ../nixos/auto-upgrade.nix
    ../nixos/bluetooth.nix
    ../nixos/fonts.nix
    ../nixos/home-manager.nix
    ../nixos/network-manager.nix
    ../nixos/nix.nix
    ../nixos/systemd-boot.nix
    ../nixos/timezone.nix
    # ../../nixos/tuigreet.nix
    ../nixos/users.nix
    ../nixos/utils.nix
    ../nixos/xdg-portal.nix
    ../nixos/variables-config.nix
    ../nixos/docker.nix
	../home/system/dae/default.nix
	# ./fhs.nix

	# niri
	../home/system/niri

    # Choose your theme here
    # ../themes/stylix/2025.nix
	];

	security.pam.loginLimits = [
		# 核心资源无限制
		{ domain = "*"; type = "-"; item = "nofile"; value = "unlimited"; }      # 文件描述符
		{ domain = "*"; type = "-"; item = "data"; value = "unlimited"; }        # 数据段大小
		{ domain = "*"; type = "-"; item = "stack"; value = "unlimited"; }       # 堆栈大小
		{ domain = "*"; type = "-"; item = "core"; value = "unlimited"; }        # 核心文件
		{ domain = "*"; type = "-"; item = "rss"; value = "unlimited"; }         # 内存使用
		{ domain = "*"; type = "-"; item = "as"; value = "unlimited"; }          # 地址空间
		{ domain = "*"; type = "-"; item = "memlock"; value = "unlimited"; }     # 锁定内存
		
		# 进程和信号无限制
		{ domain = "*"; type = "-"; item = "nproc"; value = "unlimited"; }       # 进程数
		{ domain = "*"; type = "-"; item = "sigpending"; value = "unlimited"; }  # 待处理信号
		{ domain = "*"; type = "-"; item = "msgqueue"; value = "unlimited"; }    # 消息队列
		
		# 其他资源无限制
		{ domain = "*"; type = "-"; item = "fsize"; value = "unlimited"; }       # 文件大小
		{ domain = "*"; type = "-"; item = "cpu"; value = "unlimited"; }         # CPU时间
		{ domain = "*"; type = "-"; item = "locks"; value = "unlimited"; }       # 文件锁
	];
}
