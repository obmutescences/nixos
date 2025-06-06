# Wofi is a launcher for Wayland, inspired by rofi.
{ config, pkgs, lib, ... }:
let
  accent = "#27391C";
  background = "#232a2e";
  background-alt = "#2d353b";
  foreground = "#A0D683";
  font = config.var.theme.font;
  rounding = config.var.theme.rounding;
  font-size = config.var.theme.fontSize;
in {

  home.packages = with pkgs; [ wofi-emoji ];

  programs.wofi = {
    enable = true;

    settings = {
      allow_markup = true;
      width = 450;
      show = "drun";
      prompt = "Apps";
      normal_window = true;
      layer = "top";
      term = "foot";
      height = "605px";
      orientation = "vertical";
      halign = "fill";
      line_wrap = "off";
      dynamic_lines = false;
      allow_images = true;
      image_size = 24;
      exec_search = false;
      hide_search = false;
      parse_search = false;
      insensitive = true;
      hide_scroll = true;
      no_actions = true;
      sort_order = "default";
      gtk_dark = true;
      filter_rate = 100;
      key_expand = "Tab";
      key_exit = "Escape";
    };

    style = lib.mkForce
      # css
      ''
        * {
          font-family: "${font}";
          font-weight: 500;
          font-size: ${toString font-size}px;
        }

        #window {
          background-color: ${background};
          color: ${foreground};
          border-radius: ${toString rounding}px;
        }

        #outer-box {
          padding: 20px;
        }

        #input {
          background-color: ${background-alt};
          border: 0px solid ${accent};
          color: ${foreground};
          padding: 8px 12px;
        }

        #scroll {
          margin-top: 20px;
        }

        #inner-box {}

        #img {
          padding-right: 8px;
        }

        #text {
          color: ${foreground};
        }

        #text:selected {
          color: ${foreground};
        }

        #entry {
          padding: 6px;
        }

        #entry:selected {
          background-color: ${accent};
          color: ${foreground};
        }

        #unselected {}

        #selected {}

        #input,
        #entry:selected {
          border-radius: ${toString rounding}px;
        }
      '';
  };
}
