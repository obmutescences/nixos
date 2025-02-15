{ pkgs, inputs, ... }: {

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
	  noto-fonts-cjk-sans
	  nerd-fonts.monaspace
	  comic-mono
	  openmoji-color
      twemoji-color-font
      inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    ];

    enableDefaultPackages = false;

    fontconfig = {
      defaultFonts = {
		monospace = [ "FiraCode Nerd Font Mono" "Noto Color Emoji" ];
        sansSerif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        serif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
