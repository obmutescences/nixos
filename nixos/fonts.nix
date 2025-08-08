{ pkgs, inputs, ... }: {

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
	  noto-fonts-cjk-sans
	  nerd-fonts.monaspace
	  material-symbols
	  comic-mono
	  ubuntu-sans
	  ubuntu-sans-mono
	  nerd-fonts.ubuntu-sans
      inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    ];

    enableDefaultPackages = false;

    fontconfig = {
      defaultFonts = {
		monospace = [ "Ubuntu Sans Mono" ];
        # sansSerif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        # serif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        # emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
