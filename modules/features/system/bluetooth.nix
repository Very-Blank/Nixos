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

    homeModules.bluetoothTrayService = {
      lib,
      pkgs,
      osConfig,
      ...
    }: {
      systemd.user.services.blueman-applet = lib.mkIf osConfig.hardware.bluetooth.enable {
        Unit = {
          Description = "Blueman-applet service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          Type = "Simple";
          ExecStart = "${lib.getExe' pkgs.blueman "blueman-applet"}";
          Restart = "on-failure";
          RestartSec = "1s";
          KillMode = "process";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
