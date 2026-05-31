{
  lib,
  config,
  pkgs,
  ...
}: {
  config = {
    networking = {
      hostName = config.hostname;
      networkmanager.enable = true;
    };

    # FIXME: move these:
    environment.systemPackages = lib.mkIf config.modules.graphical.bars.waybar.tray.enable [
      pkgs.libappindicator
      pkgs.networkmanagerapplet
    ];

    userHome = {
      systemd.user.services.nm-applet = lib.mkIf config.modules.graphical.bars.waybar.tray.enable {
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
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
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
