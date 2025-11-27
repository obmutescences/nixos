{
  programs.neovide = {
	enable = true;
	settings = {
		vsync = false;
		no-multigrid = false;
		maximized = false;
		idle = true;
		theme = "dark";
		font = {
			size = 15;
			normal = {
				family =  "Comic Shanns Mono";
			};
			# size = 13;
			# normal = ["UbuntuSansMono Nerd Font Mono"];

			# monofur
			# size = 15;
			# width = 1.0;
			# normal = {
			# 	family =  "Monofur Nerd Font Mono";
			# 	style = "Italic";
			# };

			# Lotion
			# size = 16;
			# width = 0.5;
			# normal = {
			# 	family =  "Lotion";
			# 	style = "Italic";
			# };
		 };
    };
  };
}
