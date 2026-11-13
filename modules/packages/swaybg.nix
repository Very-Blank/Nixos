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
      postBuild = let
        flags = [
          "--image ${cfg.background}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/swaybg"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
        ];

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
      hjem.users.${user}.files = let
        wants = ["graphical-session.target"];
        name = "swaybg.service";

        unit = self.lib.mkUnitFile pkgs name (
          {
            lib,
            pkgs,
            ...
          }: {
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
          }
        );
      in
        lib.mkMerge (
          [
            {
              ".config/systemd/user/${name}".source = unit;
            }
          ]
          ++ (map
            (wants: {".config/systemd/user/${wants}.wants/${name}".source = unit;})
            wants)
        );
    };
  };
}
