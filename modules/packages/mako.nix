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
        ''
        + lib.strings.optionalString (cfg.border != null) ''
          border-radius=${lib.toString cfg.border.radius}
          border-size=${lib.toString cfg.border.size}
        ''
        + ''

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
      postBuild = ''
        wrapProgram $out/bin/mako \
          --add-flag --config --add-flag ${pkgs.writeText "config" config} \
          --set FONTCONFIG_FILE ${fontsConf}
      '';

      meta = {
        mainProgram = "mako";
      };
    })) {};
  };

  flake = {
    configOptions.mako = {
      lib,
      pkgs,
      ...
    }: {
      options = {
        timeout = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 1500;
        };

        border = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              radius = lib.mkOption {
                type = lib.types.ints.unsigned;
              };

              size = lib.mkOption {
                type = lib.types.ints.unsigned;
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
                apply = lib.strings.replaceStrings [" "] [""];
              };

              size = lib.mkOption {
                type = lib.types.ints.unsigned;
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
    };

    userModules.makoService = user: {
      lib,
      pkgs,
      ...
    }: {
      core.services.${user}.mako = {
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

        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
