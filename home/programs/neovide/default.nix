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
			# width = 1.0;
			# size = 12;
			# normal = {
			# 	family =  "Comic Code";
			# 	style = "Italic";
			# };
			# size = 13;
			# normal = ["UbuntuSansMono Nerd Font Mono"];

			# monofur
			size = 14;
			width = 1.2;
			normal = {
				family =  "Monofur Nerd Font Mono";
				style = "W800";
			};
		 };
    };
  };
}
