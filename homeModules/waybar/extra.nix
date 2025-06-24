{pkgs, ... }: 

{
  systemd.user.services.nm-applet = {
    Unit = {
      Description = "Nm-applet service";
      PartOf = [ "graphical-session.target"  "dbus.socket" ];
      After = [ "graphical-session.target"  "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
      Restart     = "on-failure";
      RestartSec  = "5s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.blueman-applet = {
    Unit = {
      Description = "Blueman-applet service";
      PartOf = [ "graphical-session.target"  "dbus.socket" ];
      After = [ "graphical-session.target"  "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.blueman}/bin/blueman-applet";
      Restart     = "on-failure";
      RestartSec  = "5s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  programs.waybar = {
    settings = {
      mainBar = {
        modules-right = ["pulseaudio" "memory" "cpu" "backlight" "battery" "tray"];
        "tray" = {
          icon-size = 20;
          spacing = 10;
        };
      };
    };
  };
}
