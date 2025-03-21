{ inputs, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
	package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  };
}
