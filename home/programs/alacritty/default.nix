{
  programs.alacritty = {
    enable = true;
	settings = {
		window = {
			decorations = "none";
			padding = {
				x = 15;
				y = 8;
			};
		};
		scrolling.history = 10000;
		font = {
			size = 11;
			normal.family = "MonaspiceRn Nerd Font Mono";
			offset = {
				x = 1;
				y = 1;
			};
		};
		cursor.style = {
			blinking = "Always";
			shape = "Beam";
		};
		general.import = [
			"~/.config/alacritty/dank-theme.toml"
		];
	};
  };
}
