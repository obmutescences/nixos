{
  programs.neovide = {
	enable = true;
	settings = {
		vsync = true;
		no-multigrid = false;
		maximized = false;
		idle = true;
		theme = "dark";
		font = {
			# size = 15;
			# normal = {
			# 	family =  "Comic Shanns Mono";
			# };
			# size = 13;
			# normal = ["UbuntuSansMono Nerd Font Mono"];

			# monofur
			# size = 15;
			# width = 1.0;
			# normal = {
			# 	family =  "Monofur Nerd Font Mono";
			# 	style = "Italic";
			# };

			size = 13;
			width = 1.1;
			normal = {
				family =  "MonaspiceRn Nerd Font Mono";
				style = "Light Italic";
			};
		 };
    };
  };
}
