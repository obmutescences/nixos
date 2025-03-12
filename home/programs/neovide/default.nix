{
  programs.neovide = {
	enable = true;
	settings = {
		vsync = true;
		no-multigrid = false;
		maximized = false;
		srgb = true;
		idle = true;
		font = {
			size = 13;
			width = 1.1;
			# normal = {
			# 	family =  "Comic Code";
			# 	style = "Italic";
			# };
			normal = ["Ubuntu Sans Mono"];
		 };
    };
  };
}
