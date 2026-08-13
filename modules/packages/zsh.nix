{
  perSystem = {
    pkgs,
    lib,
    # system,
    # self',
    ...
  }: {
    packages.ghostty = lib.makeOverridable ({}: let
    in (pkgs.symlinkJoin {
      name = "zsh-wrapped";
      paths = [pkgs.zsh];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/zsh \
          --set ZDOTDIR "${./zsh-config-dir}"
          --set HISTFILE "$HOME/.local/state/zsh/history"
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
