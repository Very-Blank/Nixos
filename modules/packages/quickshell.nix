{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  flake = {
    homeModules.quickshellService = {
      lib,
      pkgs,
      ...
    }: {
      systemd.user.services.waybar = {
        Unit = {
          Description = "Quickshell service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          ExecStart = "${lib.getExe (self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.override {
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
