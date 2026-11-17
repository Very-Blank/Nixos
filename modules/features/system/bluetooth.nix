{
  flake = {
    nixosModules.bluetooth = {
      core.host.features = ["bluetooth"];

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };
    };

    userModules.bluetoothTrayService = user: {
      lib,
      pkgs,
      config,
      ...
    }: {
      config = lib.mkIf config.hardware.bluetooth.enable {
        core.services.${user}.blueman = {
          Unit = {
            Description = "Blueman-applet service";
            PartOf = ["graphical-session.target"];
            After = ["graphical-session.target"];
          };

          Service = {
            Type = "exec";
            ExecStart = ["${lib.getExe' pkgs.blueman "blueman-applet"}"];
            Restart = "on-failure";
            RestartSec = "1s";
            KillMode = "process";
          };

          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
