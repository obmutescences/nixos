{
  description = ''
    Nixy is a NixOS configuration with home-manager, secrets and custom theming all in one place.
    It's a simple way to manage your system configuration and dotfiles.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprspace = { url = "github:KZDKM/Hyprspace"; };
	# hyprland
    hyprland = {
      url = "github:hyprwm/hyprland";
    };
	# hyprland = { url = "git+https://github.com/hyprwm/Hyprland?submodules=1&ref=refs/tags/v0.49.0"; };
	# hyprland-plugins = {
 #      url = "github:hyprwm/hyprland-plugins";
 #      inputs.hyprland.follows = "hyprland";
 #    };
	hyprscroller = {
      url = "github:cpiber/hyprscroller";
      inputs.hyprland.follows = "hyprland";
    };
	hyprfocus = {
      url = "github:daxisunder/hyprfocus";
      inputs.hyprland.follows = "hyprland";
    };
    hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nur.url = "github:nix-community/NUR";
	zen-browser.url = "github:0xc000022070/zen-browser-flake";
	swww.url = "github:LGFae/swww";
	neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

	rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs"; # 确保它使用与您系统相同的 nixpkgs 版本
    };

	# niri wm
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
	my-niri-src = {
      url = "github:akass-org/niri/feat/blur";
      # flake = false;
    };
	my-fork-niri = {
      url = "github:obmutescences/niri/feat/blur";
      # flake = false;
    };
	quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };

	# quickshell bar theme
	dankmaterialshell.url = "github:AvengeMedia/DankMaterialShell";

	# sddm theme
	silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
   };

   };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      zerone-company = # CHANGEME: This should match the 'hostname' in your variables.nix file
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
		  specialArgs = { inherit inputs; }; # this is the important part
          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./hosts/sy-company/configuration.nix # CHANGEME: change the path to match your host folder
          ];
        };
      zerone-home = # CHANGEME: This should match the 'hostname' in your variables.nix file
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
		  specialArgs = { inherit inputs; }; # this is the important part
          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./hosts/home-desktop/configuration.nix # CHANGEME: change the path to match your host folder
          ];
        };
    };
  };
}
