{
  programs.kitty = {
    enable = true;
    keybindings = {
      # Reset existing mappings
      "ctrl+tab" = "next_tab";
	  "cmd+t" = "new_tab";
	  # "ctrl+shift+f" = "launch --type=overlay --stdin-source=@screen_scrollback fzf --no-sort --no-mouse --exact -i --tac";
	  "ctrl+shift+f" = "show_scrollback";
    };
	# font.name = "Comic Code";
	# font.name = "Monofur Nerd font Mono Italic";
	# font.size = 11;
    settings = {
      scrollback_lines = 10000;
      initial_window_width = 1200;
      initial_window_height = 600;
      update_check_interval = 0;
      enable_audio_bell = false;
      confirm_os_window_close = "0";
      remember_window_size = "no";
      disable_ligatures = "never";
      url_style = "curly";
      cursor_shape = "Underline";
      cursor_underline_thickness = 3;
      window_padding_width = 10;
	  cursor_trail = 3;
	  cursor_trail_start_threshold = 4;
	  allow_remote_control = true;
    };
	extraConfig = "
# MonaspiceRn font settings
font_size 11
font_family      family='MonaspiceRn Nerd Font Mono' postscript_name=MonaspiceRnNFM-Light style='Light Italic'
bold_font        auto
italic_font      family='MonaspiceRn Nerd Font Mono' style='Light Italic'
bold_italic_font auto

scrollback_pager nvim -u NONE -R -M -c 'lua require(\"kitty+page\")(INPUT_LINE_NUMBER)' -
cursor_trail_decay 0.5 1
map ctrl+f send_key right
map ctrl+b send_key left
modify_font cell_width 110%
modify_font cell_height 4px
visual_bell_color               none

wayland_titlebar_color          system
macos_titlebar_color            system

include dank-tabs.conf
include dank-theme.conf

background  #2a322a
";
  };
}
