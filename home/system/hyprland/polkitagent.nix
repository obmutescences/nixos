{ inputs, pkgs, ... }: {
  home.packages =
    [ inputs.hyprpolkitagent.packages."${pkgs.stdenv.hostPlatform.system}".hyprpolkitagent ];

  wayland.windowManager.hyprland.settings.exec-once =
    [ "systemctl --user start hyprpolkitagent" ];
}
