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
      config,
      ...
    }: {
      core.services.${user}.quickshell = {
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

              features = {
                # TODO: This should check what display manager the user uses.
                niriWorkspaces = true;
                audio = builtins.elem "audio" config.core.host.features;
                brightness = builtins.elem "brightness" config.core.host.features;
                battery = builtins.elem "battery" config.core.host.features;
              };
            })}"
          ];
          Restart = "on-failure";
          RestartSec = "1s";
          KillMode = "process";
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
