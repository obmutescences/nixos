{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ blueman ];
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        ControllerMode = "bredr";
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.blueman.enable = true;
}
