{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.git = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.tmux module;

      sectionToValue = name: let
        values =
          lib.mapAttrsToList
          (name: value: let
            string =
              if lib.isString value
              then value
              else if lib.isBool value
              then
                (
                  if value
                  then "true"
                  else "false"
                )
              else if lib.isInt value
              then lib.toString value
              else throw "Type not supported.";
          in "${name}=${string}")
          (lib.filterAttrs
            (_: value: (value != null) && value != [])
            cfg.${name});
      in
        if lib.hasAttr name cfg && values != []
        then [
          (lib.concatStringsSep
            "\n"
            (
              [
                "[${name}]"
              ]
              ++ values
            ))
        ]
        else [];

      configFile = pkgs.writeText "config" (
        lib.concatStringsSep "\n" (
          (lib.concatMap
            sectionToValue
            [
              "core"
              "init"
              "pull"
              "user"
            ])
          ++ [cfg.extraConfig]
        )
      );
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
