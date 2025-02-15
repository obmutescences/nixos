
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
			size = 14;
			width = 1.2;
			normal = {
				family =  "Comic Code";
				style = "Italic";
			};
			# normal = ["Comic Code"];
		 };
   };
  };
}
