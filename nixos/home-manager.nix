{ inputs, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

    users.zerone = {
      xdg.configFile."alacritty/alacritty.toml".force = true;
      xdg.configFile."mimeapps.list".force = true;
    };
  };
}
