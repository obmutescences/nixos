{ config, pkgs, ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 3d --keep 10";
    flake = "~/.config/nixos";
  };
}
