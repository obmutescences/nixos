# Hypridle is a daemon that listens for user activity and runs commands when the user is idle.
{ pkgs, ... }: {
  services.hypridle = {
    enable = false;
    settings = {
      general = {
        ignore_dbus_inhibit = false;
        # lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        # before_sleep_cmd = "loginctl lock-session";
        # after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 1800;
          # on-timeout = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        }

        # {
          # timeout = 1800;
          # on-timeout = "systemctl suspend";
        # }
      ];
    };
  };
}
