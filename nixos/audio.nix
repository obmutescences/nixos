{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."90-bluetooth-stable-lowlatency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 1024;
        "default.clock.quantum-limit" = 1024;
        "default.clock.allow-resampling" = true;
      };
    };
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-disable-camera" = {
          "wireplumber.profiles" = { main."monitor.libcamera" = "disabled"; };
        };
        "51-bluez-stable-a2dp" = {
          "monitor.bluez.properties" = {
            "override.bluez5.codecs" = [ "aac" "sbc_xq" "sbc" ];
            "bluez5.default.rate" = 48000;
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = false;
            "override.bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
          };
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };
      };
    };
  };
}
