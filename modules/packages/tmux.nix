{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.tmux = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.tmux module;

      tmuxConfig =
        ''
          set-option -s command-alias[6] q='kill-session'

          set-option -g status-keys ${cfg.keyMode}
          set-option -g mode-keys ${cfg.keyMode}
          set-option -s escape-time ${toString cfg.escapeTime}
        ''
        + (
          if cfg.prefix != null
          then ''
            unbind C-b
            set-option -g prefix ${cfg.prefix}
            bind-key ${cfg.prefix} send-prefix
          ''
          else ""
        )
        + (
          if cfg.shell != null
          then ''
            set-option -g default-shell "${cfg.shell}"
          ''
          else ""
        )
        + cfg.extraConfig;
    in
      pkgs.symlinkJoin {
        name = "tmux";
        buildInputs = [pkgs.makeWrapper];
        paths = [pkgs.tmux];
        postBuild = ''
          wrapProgram $out/bin/tmux --append-flags "-f ${pkgs.writeText "config" tmuxConfig} -L ${cfg.name}"
        '';
      });
  };
  flake = {
    configOptions.tmux = {lib}: {
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

        extraConfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Additional configuration to add to the config.";
        };
      };
    };
  };
}
