{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.git = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.tmux module;

      config = lib.strings.concatStringsSep "\n" [
        ''
          [core]
            editor = "${cfg.core.editor}"
        ''
        ''
          [init]
          	defaultBranch = "${cfg.init.defaultBranch}"
        ''

        ''
          [pull]
          	rebase = false
        ''
        (
          lib.optionalString (user != null)
          ''
            [user]
            	name = "${user.name}"
            	email = "${user.email}"
          ''
        )
        cfg.extraConfig
      ];

      configFile = pkgs.writeText "config" config;
    in (pkgs.symlinkJoin {
      name = "git";
      paths = [pkgs.git];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/git --set GIT_CONFIG_GLOBAL ${configFile}
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
