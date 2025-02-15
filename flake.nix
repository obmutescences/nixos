{
  # https://github.com/anotherhadi/nixy
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
	hyprland.url = "git+https://github.com/hyprwm/hyprland?ref=refs/tags/v0.47.2&submodules=1";
    hyprpolkitagent.url = "github:hyprwm/hyprpolkitagent";
    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    stylix.url = "github:danth/stylix";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    nur.url = "github:nix-community/NUR";
	zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations = {
      zerone = # CHANGEME: This should match the 'hostname' in your variables.nix file
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              nixpkgs.overlays =
                [ inputs.hyprpanel.overlay inputs.nur.overlays.default ];
              _module.args = { inherit inputs; };
            }
            # inputs.nixos-hardware.nixosModules.omen-16-n0005ne # CHANGEME: check https://github.com/NixOS/nixos-hardware
            inputs.home-manager.nixosModules.home-manager
            inputs.stylix.nixosModules.stylix
            ./hosts/home-desktop/configuration.nix # CHANGEME: change the path to match your host folder
	    # inputs.daeuniverse.nixosModules.dae
          ];
        };

    };
  };
}
