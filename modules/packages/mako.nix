{
  self,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.mako = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.mako module;

      palette = inputs.colors.lib.withHash self.globals.theme.palette;

      config =
        ''
          default-timeout=${lib.toString cfg.timeout}
          border-radius=${lib.toString cfg.border.radius}
          border-size=${lib.toString cfg.border.size}

          font=${cfg.font.family} ${lib.toString cfg.font.size}
        ''
        + ''
          background-color=${palette.base00}FF
          border-color=${palette.base0D}
          text-color=${palette.base05}
          progress-color=over ${palette.base02}

          ["urgency=low"]
          background-color=${palette.base00}FF
          border-color=${palette.base03}
          text-color=${palette.base05}

          ["urgency=critical"]
          background-color=${palette.base00}FF
          border-color=${palette.base08}
          text-color=${palette.base05}
        '';

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          cfg.font.package
        ];
      };
    in (pkgs.symlinkJoin {
      name = "mako";
      paths = [pkgs.mako];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--config ${pkgs.writeText "config" config}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/mako"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
          "--set FONTCONFIG_FILE ${fontsConf}"
        ];

      meta.mainProgram = "mako";
    })) {};
  };

  flake = {
    configOptions.mako = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        timeout = lib.mkOption {
          type = lib.types.int;
          default = 1500;
        };

        border = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              radius = lib.mkOption {
                type = lib.types.int;
              };

              size = lib.mkOption {
                type = lib.types.int;
              };
            };
          });

          default = {
            radius = 10;
            size = 0;
          };
        };

        font = lib.mkOption {
          type = lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
              };

              family = lib.mkOption {
                type = lib.types.nonEmptyStr;
                apply = lib.replaceStrings [" "] [""];
              };

              size = lib.mkOption {
                type = lib.types.int;
              };
            };
          };

          default = {
            package = pkgs.nerd-fonts._0xproto;
            family = "0xProto Nerd Font";
            size = 10;
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = 0 <= config.font.size;
            message = ''
              Font size can't be a negative number.
            '';
          }
          {
            assertion = 0 <= config.timeout;
            message = ''
              Timeout can't be a negative number.
            '';
          }
          {
            assertion = 0 <= config.border.size;
            message = ''
              Border size can't be a negative number.
            '';
          }
          {
            assertion = 0 <= config.border.radius;
            message = ''
              Border radius can't be a negative number.
            '';
          }
        ];
      };
    };

    userModules.makoService = user: {
      lib,
      pkgs,
      ...
    }: {
      hjem.users.${user}.files = let
        wants = ["graphical-session.target"];
        name = "mako.service";

        unit = self.lib.mkUnitFile pkgs name (
          {
            lib,
            pkgs,
            ...
          }: {
            Unit = {
              Description = "Mako service";
              PartOf = ["graphical-session.target"];
              After = ["graphical-session.target"];
            };

            Service = {
              Type = "exec";
              ExecStart = ["${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.mako}"];
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
