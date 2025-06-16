{ pkgs, ... }: {
  boot = {
    bootspec.enable = true;
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        configurationLimit = 2;
      };
    };
    tmp.cleanOnBoot = true;
    # kernelPackages =
    #   pkgs.linuxPackages_latest; # _zen, _hardened, _rt, _rt_latest, etc.
	kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_15.override {
		argsOverride = rec {
			src = pkgs.fetchurl {
					url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
					sha256 = "sha256-NFjNamxQjhYdvFQG5yuZ1dvfkp+vcEpn25ukbQdRSFg=";
		};
		version = "6.15.2";
		modDirVersion = "6.15.2";
		};
	});

    # Silent boot
    kernelParams = [
      "quiet"
      "splash"
      "vga=current"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };
}
