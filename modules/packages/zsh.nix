{
  self,
  pkgs,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.zsh = lib.makeOverridable ({
      editor ? {
        editor = "nvim";
        visual = "nvim";
      },
      history ? {
        size = 1000; # History size.
        save = 500; # How many lines to save from the history
      },
    }: let
      config = ''
        export EDITOR="${editor.editor}"
        export VISUAL="${editor.visual}"

        HISTFILE=$HOME/.zsh_history

        #fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
        #autoload -U promptinit && promptinit
        #prompt pure
      '';

      zshrc = pkgs.writeText "zsh" config;
      zshenv = pkgs.writeText "zsh" "";

      zdotdir = pkgs.linkFarm "zsh-config" [
        {
          name = ".zshrc";
          path = zshrc;
        }
        {
          name = ".zshenv";
          path = zshenv;
        }
      ];
    in (pkgs.symlinkJoin {
      name = "zsh";
      paths = [pkgs.zsh];
      buildInputs = [pkgs.makeWrapper];
      postBuild = lib.strings.concatStringsSep " " [
        "wrapProgram $out/bin/zsh"
        "--set ZDOTDIR ${zdotdir}"
      ];
    })) {};
  };
}
