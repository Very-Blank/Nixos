{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.swaybg = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.swaybg module;
    in (pkgs.symlinkJoin {
      name = "swaybg";
      paths = [pkgs.swaybg];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/swaybg \
          --add-flag --image --add-flag ${cfg.background}
      '';

      meta = {
        mainProgram = "swaybg";
      };
    })) {};
  };

  flake = {
    configOptions.swaybg = {lib, ...}: {
      options = {
        background = lib.mkOption {
          type = lib.types.path;
          default = ../../resources/wallpapers/nixos-logo-ascii.png;
        };
      };
    };

    userModules.swaybgService = user: {
      lib,
      pkgs,
      ...
    }: {
      core.services.${user}.swaybg = {
        Unit = {
          Description = "Swaybg service";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };

        Service = {
          Type = "exec";
          ExecStart = ["${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.swaybg}"];
          Restart = "on-failure";
          RestartSec = "1s";
          KillMode = "process";
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
