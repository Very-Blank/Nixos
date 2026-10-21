{
  self,
  inputs,
  ...
}: {
  perSystem = {inputs', ...}: {
    packages.quickshell = inputs'.quickshell.packages.default;
  };

  flake = {
    homeModules.quickshellService = {
      lib,
      self',
      ...
    }: {
      systemd.user.services.waybar = {
        Unit = {
          Description = "Quickshell service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          ExecStart = "${lib.getExe (self'.packages.quickshell.override {
            palette = inputs.colors.lib.withHash self.globals.theme.palette;
          })}";
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
