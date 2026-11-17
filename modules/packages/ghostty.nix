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

      configFile = pkgs.writeTextFile {
        name = "config";
        text =
          ''
            title = ${cfg.title}
            font-family = ${cfg.font.family}
            font-size = ${lib.toString cfg.font.size}
          ''
          + cfg.extraConfig;
        checkPhase = ''
          ${lib.getExe pkgs.ghostty} +validate-config --config-file=$target
        '';
      };

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          cfg.font.package
        ];
      };

      themeFile = let
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
      in
        pkgs.writeTextFile {
          name = "theme";
          text = ''
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
          checkPhase = ''
            ${lib.getExe pkgs.ghostty} +validate-config --config-file=$target
          '';
        };
    in (pkgs.symlinkJoin {
      name = "ghostty";
      paths = [pkgs.ghostty];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/ghostty \
          --add-flag --config-file=${configFile} \
          --add-flag --theme=${themeFile} \
          --set FONTCONFIG_FILE ${fontsConf}
      '';

      meta = {
        mainProgram = "ghostty";
      };
    })) {};
  };

  flake = {
    configOptions.ghostty = {
      lib,
      pkgs,
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
                type = lib.types.ints.positive;
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
    };
  };
}
