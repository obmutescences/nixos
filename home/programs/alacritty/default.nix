{
  programs.kitty = {
    enable = true;
	settings = {
		window.decorations = "none";
		opacity = 0.6;
		scrolling.history = 10000;
		font = {
			size = 10;
			normal.family = "Comic Code";
			offset = {
				x = 2;
				y = 2;
			};
		};
		cursor.style = {
			blinking = "Always";
			shape = "Beam";
		};
		colors.primary = {
			background = "#2d353b";
			foreground = "#d3c6aa";
		};
	};
  };
}
