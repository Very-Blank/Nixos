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
          wants = ["graphical-session.target"];
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
