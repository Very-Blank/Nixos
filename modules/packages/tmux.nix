{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.tmux = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.tmux module;

      tmuxQuote = value: let
        tmuxFrom = ["\\" "\"" "$"];
        tmuxTo = ["\\\\" "\\\"" "\\$"];

        quoteArg = arg: "'${lib.strings.replaceStrings (["'"] ++ tmuxFrom) (["'\\\\''"] ++ tmuxTo) arg}'";
      in ''"${
          if lib.isList value
          then lib.strings.concatMapStringsSep " " quoteArg value
          else lib.strings.replaceStrings tmuxFrom tmuxTo value
        }"'';

      tmuxConfig =
        ''
          set-option -s command-alias[6] q='kill-session'

          set-option -g status-keys ${cfg.keyMode}
          set-option -g mode-keys ${cfg.keyMode}
          set-option -s escape-time ${lib.toString cfg.escapeTime}

          set-hook -g session-created[1] 'select-window -t ${lib.toString cfg.window}'

          unbind C-b
          set-option -g prefix ${cfg.prefix}
          bind-key ${cfg.prefix} send-prefix
        ''
        + lib.strings.optionalString (cfg.shell != null) ''
          set-option -g default-shell "${cfg.shell}"
        ''
        + (lib.strings.optionalString (cfg.windows != [])
          "set-hook -g session-created[0] { ${lib.strings.concatStringsSep " ; new-window ; " (map (
              window: (lib.strings.concatStringsSep " ; " (
                (
                  lib.optional (window.cmd != null && window.cmd != [])
                  "send-keys ${tmuxQuote window.cmd} enter"
                )
                ++ (
                  lib.optional (window.name != null)
                  "rename-window ${tmuxQuote window.name}"
                )
              ))
            )
            cfg.windows)} }\n");
    in
      pkgs.symlinkJoin (finalAttrs: {
        name = "tmux";
        buildInputs = [pkgs.makeWrapper];
        paths = [pkgs.tmux];
        passthru.shellGuard = cfg.shellGuard finalAttrs.finalPackage;
        postBuild = ''
          wrapProgram $out/bin/tmux \
            --add-flag -f --add-flag ${pkgs.writeText "config" tmuxConfig} \
            --add-flag -L --add-flag ${cfg.name}
        '';

        meta = {
          mainProgram = "tmux";
        };
      })) {};
  };
  flake = {
    configOptions.tmux = {
      lib,
      config,
      ...
    }: {
      options = {
        name = lib.mkOption {
          default = "default";
          type = lib.types.str;
          description = ''
            Set the socket name that is used.
          '';
        };

        keyMode = lib.mkOption {
          default = "vi";
          example = "vi";
          type = lib.types.enum [
            "emacs"
            "vi"
          ];

          description = "VI or Emacs style shortcuts.";
        };

        escapeTime = lib.mkOption {
          default = 0;
          example = 500;
          type = lib.types.ints.unsigned;
          description = ''
            Time in milliseconds for which tmux waits after an escape is
            input.
          '';
        };

        prefix = lib.mkOption {
          default = "C-a";
          example = "C-b";
          type = lib.types.nonEmptyStr;
          description = "Set the prefix key.";
        };

        shell = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.nonEmptyStr;
          description = "Set the default-shell tmux variable.";
        };

        windows = lib.mkOption {
          example = [
            {
              name = "edit";
              cmd = ["nvim"];
            }
            {name = "shell";}
          ];
          description = ''
            Windows created in every new session. 
            Each window must set name, cmd, or both.
          '';

          type = lib.types.listOf (lib.types.submodule {
            options = {
              name = lib.mkOption {
                default = null;
                type = lib.types.nullOr lib.types.nonEmptyStr;
                description = "Name of the window.";
              };

              cmd = lib.mkOption {
                default = null;
                example = ["nvim" "."];
                type = lib.types.nullOr (lib.types.listOf lib.types.nonEmptyStr);
                description = ''
                  Command run inside the window's shell when the session is created.
                '';
              };
            };
          });
        };

        window = lib.mkOption {
          default = 0;
          type = lib.types.ints.unsigned;
          description = ''
            The selected window.
          '';
        };

        shellGuard = lib.mkOption {
          readOnly = true;
          type = lib.types.functionTo lib.types.lines;
          default = tmux: ''
            if [ -z "''${TMUX:-}" ]; then
              exec ${lib.getExe' tmux "tmux"}
              exit
            fi
          '';
          example = lib.literalExpression "self.packages.\${system}.tmux.shellGuard";
          description = ''
            Shell snippet that replaces the current shell with tmux, unless it
            is already running inside tmux. Read it from the package as
            `tmux.shellGuard`; the package passes itself in, so the snippet
            follows override and overrideAttrs.
          '';
        };
      };

      config = {
        assertions = [
          {
            assertion =
              if config.windows == []
              then config.window == 0
              else config.window < lib.length config.windows;
            message = "Window = ${lib.toString config.window} is out of range for ${lib.toString (lib.length config.windows)} window(s).";
          }
          {
            assertion = lib.all (window: window.name != null || (window.cmd != null && window.cmd != [])) config.windows;
            message = "Every entry in windows must set name or a non-empty cmd.";
          }
        ];
      };
    };
  };
}
