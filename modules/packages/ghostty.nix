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
    packages.ghostty = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.ghostty module;

      validate = ghostty-package: config:
        pkgs.runCommand "config"
        {
          inherit config;
          passAsFile = ["config"];
          buildInputs = [ghostty-package];
        }
        ''
          ghostty +validate-config --config-file=$configPath
          cp $configPath $out
        '';

      config =
        ''
          title = ${cfg.title}
          font-family = ${cfg.font.family}
          font-size = ${lib.toString cfg.font.size}
        ''
        + cfg.extraConfig;

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          cfg.font.package
        ];
      };

      theme = let
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
      in ''
        background = ${palette.base00}
        cursor-color = ${palette.base05}
        foreground = ${palette.base0B}
        palette = 0=${palette.base00}
        palette = 1=${palette.base08}
        palette = 2=${palette.base0B}
        palette = 3=${palette.base0A}
        palette = 4=${palette.base0D}
        palette = 5=${palette.base0E}
        palette = 6=${palette.base0C}
        palette = 7=${palette.base05}
        palette = 8=${palette.base03}
        palette = 9=${palette.base08}
        palette = 10=${palette.base0B}
        palette = 11=${palette.base0A}
        palette = 12=${palette.base0D}
        palette = 13=${palette.base0E}
        palette = 14=${palette.base0C}
        palette = 15=${palette.base07}
        selection-background = ${palette.base01}
        selection-foreground = ${palette.base05}
      '';
    in (pkgs.symlinkJoin {
      name = "ghostty";
      paths = [pkgs.ghostty];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--config-file=${validate pkgs.ghostty config}"
          "--theme=${validate pkgs.ghostty theme}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/ghostty"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
          "--set FONTCONFIG_FILE ${fontsConf}"
        ];

      meta = {
        mainProgram = "ghostty";
      };
    })) {};
  };

  flake = {
    configOptions.ghostty = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        title = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "Ghostty";
        };

        font = lib.mkOption {
          type = lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
              };

              family = lib.mkOption {
                type = lib.types.nonEmptyStr;
              };

              size = lib.mkOption {
                type = lib.types.int;
              };
            };
          };

          default = {
            package = pkgs.nerd-fonts._0xproto;
            family = "0xProto Nerd Font";
            size = 11;
          };
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
        };
      };

      config = {
        assertions = [
          {
            assertion = 0 < config.font.size;
            message = ''
              Font size must be bigger than zero.
            '';
          }
        ];
      };
    };
  };
}
