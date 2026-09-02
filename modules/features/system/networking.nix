{
  flake = {
    nixosModules.networking = {config, ...}: {
      networking = {
        hostName = config.core.host.name;
        networkmanager.enable = true;
      };
    };

    homeModules.networkingTray = {
      lib,
      pkgs,
      osConfig,
      ...
    }: {
      systemd.user.services.nm-applet = lib.mkIf osConfig.networking.networkmanager.enable {
        Unit = {
          Description = "Nm-applet service";
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
          ExecStart = "${lib.getExe' pkgs.networkmanagerapplet "nm-applet"}";
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
