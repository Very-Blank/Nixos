{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.tmux = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.tmux module;

      # send-keys "nvim" enter
      some = window: (lib.strings.concatStringsSep " ; " (
        (
          lib.optional (window.cmd != null && window.cmd != [])
          ''send-keys "${lib.escapeShellArgs window.cmd}" enter''
        )
        ++ (
          lib.optional (window.name != null)
          ''rename-window ${window.name}"''
        )
      ));

      # send-keys "nvim" enter ; new-window ; select-window -t 0
      wn = lib.strings.concatStringsSep " ; new-window ; " (map some cfg.windows);

      # ''
      #   send-keys "${lib.escapeShellArgs window.cmd}" enter
      #
      # '';

      tmuxConfig =
        ''
          set-option -s command-alias[6] q='kill-session'

          set-option -g status-keys ${cfg.keyMode}
          set-option -g mode-keys ${cfg.keyMode}
          set-option -s escape-time ${lib.toString cfg.escapeTime}

          set-hook -g session-created 'select-window -t 0'
        ''
        + lib.strings.optionalString (cfg.prefix != null) ''
          unbind C-b
          set-option -g prefix ${cfg.prefix}
          bind-key ${cfg.prefix} send-prefix
        ''
        + lib.strings.optionalString (cfg.shell != null) ''
          set-option -g default-shell "${cfg.shell}"
        ''
        # Or type Ctrl-b : rename-window <new name>.
        # set-hook -g session-created 'send-keys "nvim" enter ; new-window ; select-window -t 0'
        + (lib.strings.optionalString (cfg.windows != [])
          "set-hook -g session-created '${wn}'")
        + cfg.extraConfig;
    in
      pkgs.symlinkJoin {
        name = "tmux";
        buildInputs = [pkgs.makeWrapper];
        paths = [pkgs.tmux];
        postBuild = ''
          wrapProgram $out/bin/tmux \
            --add-flag -f --add-flag ${pkgs.writeText "config" tmuxConfig} \
            --add-flag -L --add-flag ${cfg.name}
        '';

        meta = {
          mainProgram = "tmux";
        };
      }) {};
  };
  flake = {
    configOptions.tmux = {lib, ...}: {
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
          type = lib.types.nullOr lib.types.str;
          description = ''
            Set the prefix key. Overrules the "shortcut" option when set.
          '';
        };

        shell = lib.mkOption {
          default = null;
          type = lib.types.nullOr lib.types.nonEmptyStr;
          description = "Set the default-shell tmux variable.";
        };

        windows = lib.mkOption {
          default = [
            {
              name = "NIXOS";
              cmd = ["nvim"];
            }
            {
              name = "NIXOS2";
              cmd = ["nvim"];
            }
          ];

          type = lib.types.listOf (lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.nullOr lib.types.nonEmptyStr;
              };

              cmd = lib.mkOption {
                type = lib.types.nullOr (lib.types.listOf lib.types.nonEmptyStr);
              };
            };
          });
        };

        window = lib.mkOption {
          default = 1;
          type = lib.types.ints.unsigned;
          description = ''
            The selected window.
          '';
        };

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional configuration added to the config.";
        };
      };

      config = {
        assertions = [
          # TODO: check window is either 0 or less than window count.
          # TODO: check that each window at least sets cmd or name!
        ];
      };
    };
  };
}
