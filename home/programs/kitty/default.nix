{
  programs.kitty = {
    enable = true;
    keybindings = {
      # Reset existing mappings
      "ctrl+tab" = "next_tab";
	  "cmd+t" = "new_tab";
	  "ctrl+shift+f" = "launch --type=overlay --stdin-source=@screen_scrollback fzf --no-sort --no-mouse --exact -i --tac";
    };
	font.name = "UbuntuSansMono Nerd Font Mono";
	font.size = 12;
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
    };
	extraConfig = "
cursor_trail_decay 0.5 1
modify_font cell_width 110%
modify_font cell_height 4px
foreground                      #d3c6aa
background                      #272e33
selection_foreground            #9da9a0
selection_background            #464e53

cursor                          #e67e80
cursor_text_color               #2e383c

url_color                       #7fbbb3

active_border_color             #a7c080
inactive_border_color           #4f5b58
bell_border_color               #e69875
visual_bell_color               none

wayland_titlebar_color          system
macos_titlebar_color            system

active_tab_background           #272e33
active_tab_foreground           #d3c6aa
inactive_tab_background         #374145
inactive_tab_foreground         #9da9a0
tab_bar_background              #2e383c
tab_bar_margin_color            none

mark1_foreground                #272e33
mark1_background                #7fbbb3
mark2_foreground                #272e33
mark2_background                #d3c6aa
mark3_foreground                #272e33
mark3_background                #d699b6

#: black
color0                          #343f44
color8                          #868d80

#: red
color1                          #e67e80
color9                          #e67e80

#: green
color2                          #a7c080
color10                         #a7c080

#: yellow
color3                          #dbbc7f
color11                         #dbbc7f

#: blue
color4                          #7fbbb3
color12                         #7fbbb3

#: magenta
color5                          #d699b6
color13                         #d699b6

#: cyan
color6                          #83c092
color14                         #83c092

#: white
color7                          #859289
color15                         #9da9a0";
  };
}
