{ pkgs, inputs, ... }: {
  stylix = {
    enable = false;

    # Edited catppuccin
    base16Scheme = {
      # base00 = "10101a"; # Default Background
      # base01 =
      #   "16161f"; # Lighter Background (Used for status bars, line number and folding marks)
      # base02 = "2b2b2b"; # Selection Background
      # base03 = "45475a"; # Comments, Invisibles, Line Highlighting
      # base04 = "585b70"; # Dark Foreground (Used for status bars)
      # base05 = "fcfcfc"; # Default Foreground, Caret, Delimiters, Operators
      # base06 = "f5e0dc"; # Light Foreground (Not often used)
      # base07 = "b4befe"; # Light Background (Not often used)
      # base08 =
      #   "f38ba8"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
      # base09 =
      #   "fab387"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
      # base0A = "f9e2af"; # Classes, Markup Bold, Search Text Background
      # base0B = "a6e3a1"; # Strings, Inherited Class, Markup Code, Diff Inserted
      # base0C =
      #   "94e2d5"; # Support, Regular Expressions, Escape Characters, Markup Quotes
      # base0D =
      #   "A594FD"; # Functions, Methods, Attribute IDs, Headings, Accent color
      # base0E =
      #   "cba6f7"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
      # base0F =
      #   "f2cdcd"; # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
	  base00 = "232a2e"; # Default Background
	  base01 = "2d353b"; # Lighter Background (Used for status bars, line number and folding marks)
	  base02 = "543a48"; # Selection Background
	  base03 = "859289"; # Comments, Invisibles, Line Highlighting
	  base04 = "9da9a0"; # Dark Foreground (Used for status bars)
	  base05 = "d3c6aa"; # Default Foreground, Caret, Delimiters, Operators
	  base06 = "f5e0dc"; # Light Foreground (Not often used)
	  base07 = "b4befe"; # Light Background (Not often used)
	  base08 = "e67e80"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
	  base09 = "dbbc7f"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
	  base0A = "f9e2af"; # Classes, Markup Bold, Search Text Background
	  base0B = "a7c080"; # Strings, Inherited Class, Markup Code, Diff Inserted
	  base0C = "94e2d5"; # Support, Regular Expressions, Escape Characters, Markup Quotes
	  base0D = "7fbbb3"; # Functions, Methods, Attribute IDs, Headings, Accent color
	  base0E = "cba6f7"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
	  base0F = "f2cdcd"; # Deprecated, Opening/Closing Embedded 
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 30;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.monaspace;
        name = "Monaspace Nerd Font";
      };
      sansSerif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };
      serif = {
        package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
        name = "SFProDisplay Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };

    polarity = "dark";
	image = /home/zerone/Pictures/Wallpapers/desktop.jpg;
    # image = pkgs.fetchurl {
    #   url =
    #     "https://github.com/anotherhadi/nixy-wallpapers/blob/main/wallpapers/"
    #     + "3.png" + "?raw=true";
    #   sha256 = "sha256-fT2ah18IAxoy3hzlLl9SkqhchzfVvZneUrZWzntMo40=";
    # };

  };

}
