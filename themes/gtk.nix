{
  pkgs,
  config,
  inputs,
  ...
}: {
  gtk = {
	enable = true;
	cursorTheme.name = "Vanilla-DMZ";
	cursorTheme.size = 30;
	iconTheme = {
      name = "Dracula-Icon-Theme";
      package = pkgs.dracula-icon-theme;
    };
	theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = "1";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = "1";
    };
    font = {
      name = "Comic Code";
      size = 14;
    };
  };
}
