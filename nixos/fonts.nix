{ pkgs, inputs, ... }: {

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
	  noto-fonts-cjk-sans
	  nerd-fonts.monaspace
	  material-symbols
	  comic-mono
	  ubuntu-sans
	  ubuntu-sans-mono
	  nerd-fonts.ubuntu-sans
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro-nerd
    ];

    enableDefaultPackages = false;

    fontconfig = {
      defaultFonts = {
		monospace = [ "Monofur Nerd Font Mono" "AaNLYDSYY (Non-Commercial Use)" ];
        sansSerif = [ "Monofur Nerd Font Mono" "AaNLYDSYY (Non-Commercial Use)" ] ;
        serif = [ "Monofur Nerd Font Mono" "AaNLYDSYY (Non-Commercial Use)" ];
        # emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
