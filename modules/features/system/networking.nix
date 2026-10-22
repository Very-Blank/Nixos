{self, ...}: {
  flake = {
    nixosModules.networking = {config, ...}: {
      networking = {
        hostName = config.core.host.name;
        networkmanager.enable = true;
      };
    };

    userModules.networkingTrayService = user: {
      lib,
      pkgs,
      config,
      ...
    }: {
      config = lib.mkIf config.networking.networkmanager.enable {
        hjem.users.${user}.files = let
          WantedBy = ["graphical-session.target"];
          name = "nm-applet.service";

          unit = self.lib.mkUnitFile pkgs name (
            {
              lib,
              pkgs,
              ...
            }: {
              Unit = {
                Description = "Nm-applet service";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session.target"];
              };

              Service = {
                Type = "exec";
                ExecStart = ["${lib.getExe' pkgs.networkmanagerapplet "nm-applet"}"];
                Restart = "on-failure";
                RestartSec = "1s";
                KillMode = "process";
              };

              Install = {
                inherit WantedBy;
              };
            }
          );
        in
          lib.mkMerge (
            [
              {
                ".config/systemd/user/${name}".source = unit;
                ".config/systemd/user/graphical-session.target.wants/${name}".source = unit;
              }
            ]
            ++ (map
              (wantedby: {".config/systemd/user/${wantedby}.wants/${name}".source = unit;})
              WantedBy)
          );
      };
    };
  };
}
