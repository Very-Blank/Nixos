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
    packages.zsh = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.zsh module;

      palette = inputs.colors.lib.withHash self.globals.theme.palette;

      menuColors = lib.mapAttrsToList (element: color: "${element}:${color}") {
        "bg+" = palette.base01;
        "fg+" = palette.base0E;
        "hl+" = palette.base0D;
        "pointer" = palette.base0E;
        "border" = palette.base02;
      };

      config = lib.strings.concatStringsSep "\n" (
        [
          (
            if cfg.keymap == "viins"
            then "bindkey -v"
            else if cfg.keymap == "vicmd"
            then "bindkey -a"
            else "bindkey -e"
          )
          ''
            source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            ZSH_AUTOSUGGEST_STRATEGY=(${lib.strings.concatStringsSep " " cfg.autosuggestion.strategies})
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${cfg.autosuggestion.highlight}"
          ''
          ''
            setopt ${
              lib.strings.concatStringsSep " " ((lib.mapAttrsToList
                (opt: on:
                  if on
                  then opt
                  else "NO_${opt}")
                {
                  "APPEND_HISTORY" = cfg.history.append;
                  "HIST_IGNORE_DUPS" = cfg.history.ignoreDups;
                  "HIST_IGNORE_SPACE" = cfg.history.ignoreSpace;
                  "SHARE_HISTORY" = cfg.history.share;
                  "EXTENDED_HISTORY" = cfg.history.extended;
                  "HIST_SAVE_BY_COPY" = cfg.history.saveByCopy;
                  "HIST_EXPIRE_DUPS_FIRST" = cfg.history.expireDuplicatesFirst;
                  "HIST_FIND_NO_DUPS" = cfg.history.findNoDups;
                  "HIST_IGNORE_ALL_DUPS" = cfg.history.ignoreAllDups;
                  "HIST_SAVE_NO_DUPS" = cfg.history.saveNoDups;
                })
              ++ ["HIST_FCNTL_LOCK" "CORRECT"])
            }
          ''
          (lib.strings.optionalString (cfg.editor != null)
            ''
              export EDITOR="${cfg.editor}"
              export VISUAL="${cfg.editor}"
            '')
          ''
            HISTSIZE="${lib.toString cfg.history.size}"
            SAVEHIST="${lib.toString cfg.history.save}"
            HISTFILE="$HOME/.zsh_history"
          ''
          ''
            fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
            autoload -U promptinit && promptinit
            prompt pure
          ''
          ''
            autoload -Uz compinit && compinit
            zstyle ':completion:*' menu select
            zstyle ':fzf-tab:*' fzf-command ${lib.getExe pkgs.fzf}
            zstyle ':fzf-tab:*' fzf-flags --color=16,${lib.strings.concatStringsSep "," menuColors} --border=rounded --pointer='▎' --gutter='▎'
            zstyle ':fzf-tab:*' fzf-pad 4
            source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          ''
          ''
            ${cfg.interactiveShellInit}
            eval "$(${lib.getExe pkgs.zoxide} init zsh --cmd cd | sed 's|command zoxide|command ${lib.getExe pkgs.zoxide}|g')"
          ''
        ]
        ++ (lib.mapAttrsToList (key: action: "bindkey '${key}' ${action}") cfg.keys)
        ++ (lib.mapAttrsToList (alias: action: "alias -- ${alias}='${action}'") cfg.aliases)
        ++ [
          ''
            source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
            ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
          ''
        ]
      );

      zshrc = pkgs.writeTextFile {
        name = "zshrc";
        text = config;
        checkPhase = ''
          ${lib.getExe pkgs.zsh} -n $target
        '';
      };

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
      passthru.shellPath = "/bin/zsh";

      postBuild = ''
        wrapProgram $out/bin/zsh \
          --set ZDOTDIR ${zdotdir}
      '';

      meta = {
        mainProgram = "zsh";
      };
    })) {};
  };

  flake = {
    configOptions.zsh = {
      lib,
      pkgs,
      ...
    }: {
      options = {
        keymap = lib.mkOption {
          type = lib.types.enum [
            "viins"
            "vicmd"
            "emacs"
          ];

          default = "viins";
        };

        editor = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
          default = null;
        };

        autosuggestion = {
          strategies = lib.mkOption {
            type = lib.types.listOf (lib.types.enum ["history" "completion"]);
            default = ["history"];
          };

          highlight = lib.mkOption {
            type = lib.types.enum [
              "black"
              "red"
              "green"
              "yellow"
              "blue"
              "magenta"
              "cyan"
              "white"
            ];
            default = "magenta";
            apply = value: "fg=${value}";
          };
        };

        keys = lib.mkOption {
          type = lib.types.attrsOf lib.types.nonEmptyStr;
          default = {
            "^Y" = "autosuggest-accept";
          };
        };

        aliases = lib.mkOption {
          type = lib.types.attrsOf lib.types.nonEmptyStr;
          default = {};
        };

        history = {
          size = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 1000;
          };

          save = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 1000;
          };

          append = lib.mkEnableOption "Append to the history file instead of overwriting it.";
          ignoreDups =
            lib.mkEnableOption "Don't record a command identical to the previous one."
            // {
              default = true;
            };
          ignoreSpace =
            lib.mkEnableOption "Don't record commands that start with a space."
            // {
              default = true;
            };
          share =
            lib.mkEnableOption "Share history between all running sessions."
            // {
              default = true;
            };

          extended = lib.mkEnableOption "Save timestamps and durations in the history file.";
          saveByCopy = lib.mkEnableOption "Write a new history file and rename it instead of overwriting in place.";
          expireDuplicatesFirst = lib.mkEnableOption "Expire duplicates first when the history exceeds its size.";
          findNoDups = lib.mkEnableOption "Skip duplicates when searching history.";
          ignoreAllDups = lib.mkEnableOption "Remove older duplicates when a new command is added.";
          saveNoDups = lib.mkEnableOption "Omit duplicates when writing the history file.";
        };

        interactiveShellInit = lib.mkOption {
          default = "";
          description = ''
            Shell script code called during interactive zsh shell initialisation.
          '';
          type = lib.types.lines;
        };
      };

      config = {
        aliases = lib.mapAttrs (_: lib.mkDefault) {
          "gc" = "git checkout";
          "gca" = "git commit -a";
          "glm" = "git pull origin main";
          "gsm" = "git push origin main";
          "ls" = "${lib.getExe pkgs.eza} --icons always --color always --no-quotes --group-directories-first";
        };
      };
    };
  };
}
