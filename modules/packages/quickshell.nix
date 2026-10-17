{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system};
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
          ExecStart = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell}";
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
