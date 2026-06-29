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
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 128;
        "default.clock.max-quantum" = 256;
        "default.clock.quantum-limit" = 256;
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
        # 修复 AMD Starship/Matisse + ALC897 有线耳机问题
        # ACP (AMD Audio CoProcessor) 模式对这个 HDA-Intel ALC897 声卡
        # 存在两个问题：
        #   1. 没有 Jack 插拔检测 (ACP 绕过 HDA jack 检测)
        #   2. 声道位置错误 (AUX 而不是 FL/FR)
        # 标准 HDA ALSA 模式才能正确支持插孔检测和声道映射
        "60-alsa-default" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "device.name" = "~alsa_card.pci-0000_2d_00.*"; }
              ];
              actions = {
                "update-props" = {
                  "api.acp.auto-profile" = true;
                  "api.acp.auto-port" = true;
                  # 使用标准 ALSA HDA 模式而非 ACP，以确保插孔检测功能正常
                  "api.alsa.use-acp" = false;
                };
              };
            }
          ];
        };
      };
    };
  };
}
