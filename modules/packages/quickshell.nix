{
  self,
  inputs,
  ...
}: {
  perSystem = {inputs', ...}: {
    packages.quickshell = inputs'.quickshell.packages.default;
  };

  flake = {
    userModules.quickshellService = user: {
      lib,
      pkgs,
      ...
    }: {
      hjem.users.${user}.files = let
        WantedBy = ["graphical-session.target"];
        name = "quickshell.service";

        unit = self.lib.mkUnitFile pkgs name (
          {
            lib,
            pkgs,
            ...
          }: {
            Unit = {
              Description = "Quickshell service";
              PartOf = ["graphical-session.target"];
              After = ["graphical-session.target"];
            };

            Service = {
              Type = "exec";
              ExecStart = [
                "${lib.getExe (self.packages.${pkgs.stdenv.hostPlatform.system}.quickshell.override {
                  palette = inputs.colors.lib.withHash self.globals.theme.palette;
                })}"
              ];
              Restart = "on-failure";
              RestartSec = "1s";
              KillMode = "process";
            };

            Install = {
              inherit WantedBy;
            };
          }
        );
      in
        lib.mkMerge (
          [
            {
              ".config/systemd/user/${name}".source = unit;
              ".config/systemd/user/graphical-session.target.wants/${name}".source = unit;
            }
          ]
          ++ (map
            (wantedby: {".config/systemd/user/${wantedby}.wants/${name}".source = unit;})
            WantedBy)
        );
    };
  };
}
