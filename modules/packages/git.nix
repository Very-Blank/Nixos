{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.git = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.git module;

      configFile = pkgs.writeTextFile {
        name = "config";
        text =
          lib.generators.toGitINI (
            lib.filterAttrs (_: section: section != {}) (
              lib.mapAttrs (_: lib.filterAttrs (_: value: value != null)) {
                inherit (cfg) core init pull user;
              }
            )
          )
          + cfg.extraConfig;
        checkPhase = ''
          ${lib.getExe pkgs.git} config --file $target --list > /dev/null
        '';
      };
    in (pkgs.symlinkJoin {
      name = "git";
      paths = [pkgs.git];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/git \
          --set GIT_CONFIG_GLOBAL ${configFile}
      '';

      meta = {
        mainProgram = "git";
      };
    })) {};
  };

  flake = {
    configOptions.git = {lib, ...}: {
      options = {
        core = {
          editor = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
          };
        };

        init = {
          defaultBranch = lib.mkOption {
            type = lib.types.nonEmptyStr;
            default = "main";
          };
        };

        pull = {
          rebase = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };

        user = {
          name = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
          };

          email = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
          };
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional configuration added to the config.";
        };
      };
    };
  };
}
