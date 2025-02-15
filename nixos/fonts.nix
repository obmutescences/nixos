{ pkgs, inputs, ... }: {

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
	  noto-fonts
	  noto-fonts-cjk-sans
	  nerd-fonts.monaspace
	  comic-mono
    ];

    enableDefaultPackages = false;

    fontconfig = {
      defaultFonts = {
		monospace = ["Comic mono"];
        sansSerif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        serif = [ "SFProDisplay Nerd Font" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
