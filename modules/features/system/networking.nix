{
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
        core.services.${user}.nm-applet = {
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

          Install.WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
