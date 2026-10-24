{self, ...}: {
  flake = {
    core.host.features = ["bluetooth"];

    nixosModules.bluetooth = {
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
        hjem.users.${user}.files = let
          wants = ["graphical-session.target"];
          name = "blueman.service";

          unit = self.lib.mkUnitFile pkgs name (
            {
              lib,
              pkgs,
              ...
            }: {
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
            }
          );
        in
          lib.mkMerge (
            [
              {
                ".config/systemd/user/${name}".source = unit;
              }
            ]
            ++ (map
              (wants: {".config/systemd/user/${wants}.wants/${name}".source = unit;})
              wants)
          );
      };
    };
  };
}
