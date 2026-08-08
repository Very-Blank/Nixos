{
  pkgs,
  lib,
  niri-flake,
  ...
}: let
  mkNiriConfig = settings:
    (lib.evalModules {
      modules = [
        niri-flake.lib.internal.settings-module
        {config.programs.niri.settings = settings;}
      ];
    }).config.programs.niri.finalConfig;

  config = mkNiriConfig {
    input.keyboard.xkb.layout = "us";
    outputs."eDP-1".scale = 2.0;
  };

  kdlConfig =
    niri-flake.lib.internal.validated-config-for
    pkgs
    pkgs.niri
    config;
in {
  packages.niri = pkgs.symlinkJoin {
    name = "niri";
    paths = [pkgs.niri];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/niri --add-flags "--config ${kdlConfig}"
    '';
  };
}
