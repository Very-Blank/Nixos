{
  # self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    # system,
    # self',
    ...
  }: {
    packages.ghostty = lib.makeOverridable ({
      cellAdjust ? {
        height = "-10%";
        width = "-10%";
      },
      title ? "Ghostty",
      palette ? null,
      fontFamily ? null,
      extraConfig ? null,
    }: let
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
          adjust-cell-height = ${cellAdjust.height}
          adjust-cell-width = ${cellAdjust.width}
          title = ${title}
        ''
        + lib.optionalString (fontFamily != null) ''
          font-family = ${fontFamily}
        ''
        + lib.optionalString (extraConfig != null) extraConfig;

      theme = ''
        background = #${palette.base00}
        cursor-color = #${palette.base05}
        foreground = #${palette.base0B}
        palette = 0=#${palette.base00}
        palette = 1=#${palette.base08}
        palette = 2=#${palette.base0B}
        palette = 3=#${palette.base0A}
        palette = 4=#${palette.base0D}
        palette = 5=#${palette.base0E}
        palette = 6=#${palette.base0C}
        palette = 7=#${palette.base05}
        palette = 8=#${palette.base03}
        palette = 9=#${palette.base08}
        palette = 10=#${palette.base0B}
        palette = 11=#${palette.base0A}
        palette = 12=#${palette.base0D}
        palette = 13=#${palette.base0E}
        palette = 14=#${palette.base0C}
        palette = 15=#${palette.base07}
        selection-background = #${palette.base01}
        selection-foreground = #${palette.base05}
      '';
    in (pkgs.symlinkJoin {
      name = "ghostty";
      paths = [pkgs.ghostty];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags =
          [
            "--config-file=${validate pkgs.ghostty config}"
          ]
          ++ (
            lib.optional (palette != null)
            "--theme=${validate pkgs.ghostty theme}"
          );
      in ''
        wrapProgram $out/bin/ghostty --add-flags "${lib.strings.concatStringsSep " " flags}"
      '';
    })) {};
  };

  flake = {
    nixosModules.ghostty = {...}: {
      programs.ghostty = {
        enable = true;
      };
    };
  };
}
