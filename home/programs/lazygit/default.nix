{ config, lib, ... }:
let
  accent = "#7fbbb3";
  muted = "#$859289";
in {
  programs.lazygit = {
    enable = true;
    settings = lib.mkForce {
      gui = {
        theme = {
          activeBorderColor = [ accent "bold" ];
          inactiveBorderColor = [ muted ];
        };
        showListFooter = false;
        showRandomTip = false;
        showCommandLog = false;
        showBottomLine = false;
        nerdFontsVersion = "3";
      };
    };
  };
}
