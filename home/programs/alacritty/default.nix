{
  programs.alacritty = {
    enable = true;
	settings = {
		window.decorations = "none";
		scrolling.history = 10000;
		font = {
			size = 12;
			normal.family = "Comic Code";
			offset = {
				x = 2;
				y = 1;
			};
		};
		cursor.style = {
			blinking = "Always";
			shape = "Beam";
		};
		colors = {
			primary = {
				background = "#2d353b";
				foreground = "#d3c6aa";
			};
		};
	};
  };
}
