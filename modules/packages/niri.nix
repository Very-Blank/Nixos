{
  self,
  inputs,
  ...
}: let
in {
  perSystem = {
    pkgs,
    lib,
    system,
    # self',
    ...
  }: {
    packages.niri = lib.makeOverridable ({
      terminal ? null,
      launcher ? null,
    }: let
      niri-unstable = inputs.niri.packages.${system}.niri-unstable;

      mkNiriConfig = settings:
        (lib.evalModules {
          modules = [
            inputs.niri.lib.internal.settings-module
            {config.programs.niri.settings = settings;}
          ];
        }).config.programs.niri.finalConfig;

      config = mkNiriConfig {
        input = {
          keyboard = {
            repeat-delay = 150;
          };
        };

        hotkey-overlay = {
          skip-at-startup = true;
        };

        # cursor = let in {
        #   theme = cursorName;
        #   size = cursorSize;
        # };

        screenshot-path = "~/Pictures/Screenshots/Screenshot%Y_%m_%d_%H_%M_%S.png";

        prefer-no-csd = true;

        spawn-at-startup = [
          {command = ["xwayland-satellite"];}
        ];

        environment = {
          DISPLAY = ":0";
        };

        layout = {
          gaps = 8;
          center-focused-column = "never";

          preset-column-widths = [
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
          ];

          default-column-width = {
            proportion = 1.0 / 2.0;
          };

          focus-ring = {
            active = {
              gradient = {
                to = "rgb(127 200 255)";
                from = "rgb(120 000 200)";
                angle = 45;
              };
            };

            inactive = {
              color = "rgb(127 200 255)";
            };
          };

          tab-indicator = {
            width = 4;
            gap = 4;
            position = "top";
            place-within-column = true;

            active = {
              gradient = {
                to = "rgb(127 200 255)";
                from = "rgb(120 000 200)";
                angle = 45;
              };
            };
          };
        };

        binds = lib.mkMerge [
          {
            "Mod+H".action.focus-column-left = {};
            "Mod+J".action.focus-window-down = {};
            "Mod+K".action.focus-window-up = {};
            "Mod+L".action.focus-column-right = {};

            "Mod+Shift+H".action.move-column-left = {};
            "Mod+Shift+J".action.move-window-down = {};
            "Mod+Shift+K".action.move-window-up = {};
            "Mod+Shift+L".action.move-column-right = {};

            "Mod+Ctrl+H".action.focus-monitor-left = {};
            "Mod+Ctrl+J".action.focus-monitor-down = {};
            "Mod+Ctrl+K".action.focus-monitor-up = {};
            "Mod+Ctrl+L".action.focus-monitor-right = {};

            "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
            "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = {};
            "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = {};
            "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};

            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

            "Mod+R".action.switch-preset-column-width = {};
            "Mod+F".action.maximize-column = {};
            "Mod+Shift+F".action.fullscreen-window = {};

            "Mod+C".action.center-column = {};
            "Mod+V".action.toggle-window-floating = {};

            "Mod+Shift+S".action.screenshot = {};
            "Print".action.screenshot-screen = {};

            "Mod+Q".action.close-window = {};
            "Mod+Shift+E".action.quit = {};

            "Mod+Semicolon".action.spawn = [
              "${lib.getExe pkgs.wtype}"
              "ö"
            ];

            "Mod+Apostrophe".action.spawn = [
              "${lib.getExe pkgs.wtype}"
              "ä"
            ];

            "Mod+Shift+Semicolon".action.spawn = [
              "${lib.getExe pkgs.wtype}"
              "Ö"
            ];

            "Mod+Shift+Apostrophe".action.spawn = [
              "${lib.getExe pkgs.wtype}"
              "Ä"
            ];
          }
          (lib.listToAttrs (map (num: {
            name = "Mod+${toString num}";
            value.action.focus-workspace = num;
          }) (lib.range 1 9)))

          (lib.mkIf (terminal != null)
            {
              "Mod+T".action.spawn = "${lib.getExe terminal}";
            })

          (lib.mkIf (launcher != null)
            {
              "Mod+D".action.spawn = "${lib.getExe launcher}";
            })
        ];
      };

      kdlConfig =
        inputs.niri.lib.internal.validated-config-for
        pkgs
        niri-unstable
        config;
    in (pkgs.symlinkJoin {
      name = "niri";
      paths = [niri-unstable];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/niri --add-flags "--config ${kdlConfig}"
      '';
    })) {};
  };

  flake = {
    nixosModules.niri = {
      pkgs,
      # lib,
      ...
    }: {
      programs.niri = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri;
      };
    };

    homeModules.niri = {...}: {
    };
  };
}
