{
  flake = {
    nixosModules.networking = {config, ...}: {
      networking = {
        hostName = config.core.host.name;
        networkmanager.enable = true;
      };
    };

    homeModules.networkingTrayService = {
      lib,
      pkgs,
      osConfig,
      ...
    }: {
      systemd.user.services.nm-applet = lib.mkIf osConfig.networking.networkmanager.enable {
        Unit = {
          Description = "Nm-applet service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          Type = "Simple";
          ExecStart = "${lib.getExe' pkgs.networkmanagerapplet "nm-applet"}";
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
