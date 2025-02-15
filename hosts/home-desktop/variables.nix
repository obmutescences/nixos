{ config, ... }: {
  imports = [ ../../nixos/variables-config.nix ];

  config.var = {
    hostname = "zerone";
    username = "zerone";
    configDirectory = "/home/" + config.var.username
      + "/.config/nixos"; # The path of the nixos configuration directory

    keyboardLayout = "us";

    location = "Guangzhou";
    timeZone = "Asia/Shanghai";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "en_US.UTF-8";

    git = {
      username = "zerone";
      email = "913108060@qq.com";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;

    # Choose your theme variables here
    theme = import ../../themes/var/2025.nix;
  };
}
