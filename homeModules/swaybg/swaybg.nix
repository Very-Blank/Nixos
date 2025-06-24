{config, pkgs, ...}:

{
  home.file."Pictures/wallpaper.png".source = ./wallpaper.png;
  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaybg background service";
      PartOf = [ "graphical-session.target"  "dbus.socket" ];
      After = [ "graphical-session.target"  "dbus.socket" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.home.homeDirectory}/Pictures/wallpaper.png -m fill";
      Restart     = "on-failure";
      RestartSec  = "5s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
