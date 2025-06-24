{config, ...}:

{
  programs.niri = {
    settings = {
      input = {
        keyboard = {
          repeat-delay = 150;
        };
      };

      hotkey-overlay = {
        skip-at-startup = true;
      };

      cursor = {
        theme = "Bibata-Original-Classic";
        size = 16;
      };

      screenshot-path = "~/Pictures/Screenshots/Screenshot%Y_%m_%d_%H_%M_%S.png";

      prefer-no-csd = true;

      spawn-at-startup = [
        { command = ["xwayland-satellite"]; }
      ];

      environment = {
          DISPLAY =  ":0";
      };

      layout =  {
        gaps = 8;
        center-focused-column = "never";

        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width = { proportion = 1.0 / 2.0; };

        focus-ring = {
          active = {
            gradient = {
              to = "rgb(127 200 255)";
              from = "rgb(120 000 200)";
              angle = 45;
            };
          };
          inactive ={
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

      window-rules = [
        {
          draw-border-with-background = false;
          geometry-corner-radius = let radius = 4.0; in {
            top-left = radius;
            top-right = radius;
            bottom-left = radius;
            bottom-right = radius;
          };
          clip-to-geometry = true;
        }

        {
          matches = [{ app-id = "^firefox$"; title = "^Picture-in-Picture$"; }];
          open-floating = true;
        }

        {
          matches = [{ app-id = "^\\.blueman-manager-wrapped$"; }];
          open-floating = true;
          max-width = 600;
          min-width = 600;
          max-height = 400;
          min-height = 400;
        }

        {
          matches = [{ app-id = "^nm-connection-editor$"; }];
          open-floating = true;
        }
      ];

      binds = with config.lib.niri.actions; let sh = spawn "sh" "-c"; in {
        "Mod+H".action = focus-column-left;
        "Mod+J".action = focus-window-down;
        "Mod+K".action = focus-window-up;
        "Mod+L".action = focus-column-right;

        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+J".action = move-window-down;
        "Mod+Shift+K".action = move-window-up;
        "Mod+Shift+L".action = move-column-right;

        "Mod+Ctrl+H".action = focus-monitor-left;
        "Mod+Ctrl+J".action = focus-monitor-down;
        "Mod+Ctrl+K".action = focus-monitor-up;
        "Mod+Ctrl+L".action = focus-monitor-right;

        "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

        "Mod+1".action = focus-workspace 1;
        "Mod+2".action = focus-workspace 2;
        "Mod+3".action = focus-workspace 3;
        "Mod+4".action = focus-workspace 4;
        "Mod+5".action = focus-workspace 5;
        "Mod+6".action = focus-workspace 6;
        "Mod+7".action = focus-workspace 7;
        "Mod+8".action = focus-workspace 8;
        "Mod+9".action = focus-workspace 9;
        # "Mod+Ctrl+1".action = move-column-to-workspace 1;
        # "Mod+Ctrl+2".action = move-column-to-workspace 2;
        # "Mod+Ctrl+3".action = move-column-to-workspace 3;
        # "Mod+Ctrl+4".action = move-column-to-workspace 4;
        # "Mod+Ctrl+5".action = move-column-to-workspace 5;
        # "Mod+Ctrl+6".action = move-column-to-workspace 6;
        # "Mod+Ctrl+7".action = move-column-to-workspace 7;
        # "Mod+Ctrl+8".action = move-column-to-workspace 8;
        # "Mod+Ctrl+9".action = move-column-to-workspace 9;

        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";
        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";

        "Mod+R".action = switch-preset-column-width;
        "Mod+F".action = maximize-column;

        "Mod+C".action = center-column;
        "Mod+V".action = toggle-window-floating;

        "Print".action = screenshot;
        "Mod+Print".action = screenshot-window;

        "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
        "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        "Mod+Q".action = close-window;
        "Mod+Shift+E".action = quit;
        "Mod+D".action = spawn "fuzzel";
        "Mod+T".action = spawn "ghostty";

        "Mod+Semicolon".action = spawn ["wtype" "ö"];
        "Mod+Apostrophe".action = spawn ["wtype" "ä"];
        "Mod+Shift+Semicolon".action = spawn ["wtype" "Ö"];
        "Mod+Shift+Apostrophe".action = spawn ["wtype" "Ä"];
      };
    };
  };
}
