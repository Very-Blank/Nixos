{
  flake = {
    nixosModules.bluetooth = {
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };
    };

    homeModules.bluetoothTray = {
      lib,
      pkgs,
      osConfig,
      ...
    }: {
      systemd.user.services.blueman-applet = lib.mkIf osConfig.hardware.bluetooth.enable {
        Unit = {
          Description = "Blueman-applet service";

          PartOf = [
            "graphical-session.target"
            "dbus.socket"
          ];

          After = [
            "graphical-session.target"
            "dbus.socket"
          ];
        };

        Service = {
          ExecStart = "${lib.getExe' pkgs.blueman "blueman-applet"}";
          Restart = "on-failure";
          RestartSec = "5s";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
