{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      hardware = {
        backlight = {
          enable = lib.mkEnableOption "Enables backlight for screens.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.hardware.backlight;
  in
    lib.mkIf cfg.enable {
      environment.systemPackages = [pkgs.brightnessctl];

      services = {
        actkbd = {
          enable = true;
          bindings = [
            {
              keys = [224];
              events = ["key"];
              command = "/run/current-system/sw/bin/brightnessctl set 5%-";
            }
            {
              keys = [225];
              events = ["key"];
              command = "/run/current-system/sw/bin/brightnessctl set +5%";
            }
          ];
        };
      };
    };
}
