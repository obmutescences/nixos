{
  pkgs,
  config,
  inputs,
  ...
}: {

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 17;
  };

  gtk = {
	enable = true;
	cursorTheme.name = "Bibata-Modern-Classic";
	cursorTheme.size = 17;
	iconTheme = {
      name = "Dracula-Icon-Theme";
      package = pkgs.dracula-icon-theme;
    };
	theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    font = {
      name = "Comic Code";
      size = 13;
    };
  };
}
