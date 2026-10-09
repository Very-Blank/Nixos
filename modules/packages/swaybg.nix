{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.swaybg = lib.makeOverridable ({background ? ../../resources/wallpapers/nixos-logo-ascii.png}: let
    in (pkgs.symlinkJoin {
      name = "swaybg";
      paths = [pkgs.swaybg];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--image ${background}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/swaybg"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
        ];

      meta.mainProgram = "swaybg";
    })) {};
  };

  flake = {
    homeModules.swaybgService = {
      lib,
      pkgs,
      ...
    }: {
      systemd.user.services.swaybg = {
        Unit = {
          Description = "Swaybg service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.swaybg}";
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
