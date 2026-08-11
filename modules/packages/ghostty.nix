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
    packages.ghostty = lib.makeOverridable ({palette ? null}: let
      validatedFor = ghostty-package: config:
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

      config = ''
        adjust-cell-height = -10%
        adjust-cell-width = -10%
        font-family = 0xProto Nerd Font Mono
        title = Ghostty
      '';

      theme = ''
        background = #${palette.base00}
        cursor-color = #${palette.base05}
        foreground = #${palette.base0B}
        palette0 = #${palette.base00}
        palette1 = #${palette.base08}
        palette2 = #${palette.base0B}
        palette3 = #${palette.base0A}
        palette4 = #${palette.base0D}
        palette5 = #${palette.base0E}
        palette6 = #${palette.base0C}
        palette7 = #${palette.base05}
        palette8 = #${palette.base03}
        palette9 = #${palette.base08}
        palette10 = #${palette.base0B}
        palette11 = #${palette.base0A}
        palette12 = #${palette.base0D}
        palette13 = #${palette.base0E}
        palette14 = #${palette.base0C}
        palette15 = #${palette.base07}
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
            "--config-file=${validatedFor pkgs.ghostty config}"
          ]
          ++ (lib.optional (palette != null) [
            "--theme=${validatedFor "theme" theme}"
          ]);
      in ''
        wrapProgram $out/bin/ghostty --add-flags "${lib.strings.concatStringsSep " " flags}"
      '';
    })) {};
  };
}
