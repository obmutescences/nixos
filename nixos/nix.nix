{ config, inputs, ... }:
let autoGarbageCollector = config.var.autoGarbageCollector;
in {
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
  };

  nix = {
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    channel.enable = false;
    extraOptions = ''
      warn-dirty = false
    '';
    settings = {
	  trusted-users = ["zerone"];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ 
			"https://mirrors.ustc.edu.cn/nix-channels/store"
			"https://cache.nixos.org" 
			"https://nix-community.cachix.org"
			"https://hyprland.cachix.org"
		];
      trusted-public-keys = [
		"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
		"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
	  download-buffer-size = 2024288000; # 设置为 500 MiB
    };
    gc = {
      automatic = autoGarbageCollector;
      persistent = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
