{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.zsh = lib.makeOverridable ({
      keyMap ? "viins",
      autosuggestion ? {
        strategies = ["history"];
        highlight = "fg=magenta";
      },
      opts ? [
        "HIST_FCNTL_LOCK"
        "HIST_IGNORE_DUPS"
        "HIST_IGNORE_SPACE"
        "SHARE_HISTORY"
        "NO_APPEND_HISTORY"
        "NO_EXTENDED_HISTORY"
        "NO_HIST_EXPIRE_DUPS_FIRST"
        "NO_HIST_FIND_NO_DUPS"
        "NO_HIST_IGNORE_ALL_DUPS"
        "NO_HIST_SAVE_NO_DUPS"
      ],
      editor ? {
        editor = "nvim";
        visual = "nvim";
      },
      history ? {
        size = 1000; # History size.
        save = 1000; # How many lines to save from the history
      },
      keys ? [
        {
          key = "^Y";
          action = "autosuggest-accept";
        }
      ],
      aliases ? [
        {
          alias = "gc";
          action = "git checkout";
        }
        {
          alias = "gca";
          action = "git commit -a";
        }
        {
          alias = "glm";
          action = "git pull origin main";
        }
        {
          alias = "gsm";
          action = "git push origin main";
        }
        {
          alias = "ls";
          action = "ls --color=auto -h --group-directories-first";
        }
        {
          alias = "ns";
          action = "nix-shell --run zsh";
        }
      ],
    }: let
      config = lib.strings.concatStringsSep "\n" (
        [
          (
            if keyMap == "viins"
            then "bindkey -v"
            else if keyMap == "vicmd"
            then "bindkey -a"
            else "bindkey -e"
          )
          ''
            source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            ${
              lib.optionalString (autosuggestion.strategies != [])
              ''
                ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " autosuggestion.strategies})
              ''
            }
            ${
              lib.optionalString (autosuggestion.highlight != null)
              ''
                ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${autosuggestion.highlight}"
              ''
            }
          ''
          ''
            setopt ${lib.strings.concatStringsSep " " opts}
          ''
          ''
            export EDITOR="${editor.editor}"
            export VISUAL="${editor.visual}"
          ''
          ''
            HISTSIZE="${lib.toString history.size}"
            SAVEHIST="${lib.toString history.save}"
            HISTFILE="$HOME/.zsh_history"
          ''
          ''
            fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
            autoload -U promptinit && promptinit
            prompt pure
          ''
        ]
        ++ (map (key: "bindkey '${key.key}' ${key.action}") keys)
        ++ (map (alias: "alias -- ${alias.alias}='${alias.action}'") aliases)
        ++ [
          ''
            source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
          ''
        ]
      );

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
