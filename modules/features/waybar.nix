{
  self,
  inputs,
  ...
}: {
  flake = {
    homeModules.waybar = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        modules = {
          waybar = {
            features = lib.mkOption {
              default = [];
              description = "Extra features to be enabled.";
              type = with lib.types;
                listOf (enum [
                  "tray"
                  "audio"
                  "time"
                  "system-info"
                  "backlight"
                  "battery"
                ]);
            };
          };
        };
      };

      config = let
        cfg = config.modules.waybar;
      in {
        home = {
          packages = [
            pkgs.nerd-fonts._0xproto
          ];
        };

        fonts = {
          fontconfig = {
            enable = true;
          };
        };

        programs.waybar = {
          enable = true;

          style = self.css.waybar {
            theme = inputs.colors.lib.withHash self.globals.theme.palette;
            fontFamily = "0xProto Nerd Font";
            fontWeight = "normal";
          };

          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              margin = "5 10 5 10";
              modules-center = ["clock"];

              modules-left = lib.mkMerge [
                (lib.mkIf config.wayland.windowManager.niri.enable ["niri/workspaces"])
                [
                  "keyboard-state"
                  "custom/poweroff"
                  "custom/hibernate"
                  "custom/reboot"
                ]
              ];

              modules-right = lib.mkMerge [
                (lib.mkIf (builtins.elem "audio" cfg.features) ["pulseaudio"])
                (lib.mkIf (builtins.elem "backlight" cfg.features) ["backlight"])
                (lib.mkIf (builtins.elem "system-info" cfg.features) [
                  "memory"
                  "cpu"
                ])
                (lib.mkIf (builtins.elem "battery" cfg.features) ["battery"])
                (lib.mkIf (builtins.elem "tray" cfg.features) ["tray"])
              ];

              "keyboard-state" = {
                capslock = true;
                format = "{icon}";
                format-icons = {
                  locked = "";
                  unlocked = "";
                };
              };

              "clock" = {
                format = "{:%a %d %b %I:%M %p}";
                tooltip = false;
              };

              "custom/poweroff" = {
                format = "";
                on-double-click = "poweroff";
                tooltip = false;
              };

              "custom/hibernate" = {
                format = "⭘";
                on-double-click = "systemctl hibernate";
                tooltip = false;
              };

              "custom/reboot" = {
                format = "";
                on-double-click = "reboot";
                tooltip = false;
              };

              "pulseaudio" = lib.mkIf (builtins.elem "audio" cfg.features) {
                reverse-scrolling = 1;
                format = "{volume}% {icon}  {format_source}";
                format-bluetooth = "{volume}% {icon} {format_source}";
                format-bluetooth-muted = " {icon} {format_source}";
                format-muted = " {format_source}";
                format-source = "{volume}% ";
                format-source-muted = "";
                format-icons = {
                  headphone = "";
                  hands-free = "";
                  headset = "";
                  phone = "";
                  portable = "";
                  car = "";
                  default = [
                    ""
                    ""
                    ""
                  ];
                };
                on-click = "${lib.getExe pkgs.pavucontrol}";
                min-length = 13;
                tooltip = false;
              };

              "memory" = lib.mkIf (builtins.elem "system-info" cfg.features) {
                interval = 30;
                format = "{}% ";
                tooltip = false;
              };

              "cpu" = lib.mkIf (builtins.elem "system-info" cfg.features) {
                interval = 2;
                format = "{usage}% ";
                min-length = 6;
                tooltip = false;
              };

              "backlight" = lib.mkIf (builtins.elem "backlight" cfg.features) {
                device = "intel_backlight";
                format = "{percent}% {icon}";
                format-icons = [
                  "󰛩"
                  "󱩎"
                  "󱩏"
                  "󱩐"
                  "󱩑"
                  "󱩒"
                  "󱩓"
                  "󱩔"
                  "󱩕"
                  "󱩖"
                  "󰛨"
                ];
                min-length = 7;
                tooltip = false;
              };

              "battery" = lib.mkIf (builtins.elem "battery" cfg.features) {
                interval = 2;
                states = {
                  warning = 30;
                  critical = 15;
                };
                format = "{capacity}% {icon}";
                format-charging = "{capacity}% 󰂄";
                format-plugged = "{capacity}% ";
                format-alt = "{time} {icon}";
                format-icons = [
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                  "󰁹"
                ];
                tooltip = false;
              };

              "tray" = lib.mkIf (builtins.elem "tray" cfg.features) {
                icon-size = 20;
                spacing = 10;
                tooltip = false;
              };
            };
          };
        };
      };
    };

    css.waybar = {
      theme,
      fontFamily,
      fontWeight,
    }: ''
      * {
          border: none;
          border-radius: 0;
          font-family: '${fontFamily}';
          font-weight: ${fontWeight};
          min-height: 20px;
      }

      window#waybar {
          background: transparent;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      #workspaces {
          margin-right: 8px;
          border-radius: 10px;
          transition: none;
          background: ${theme.base00};
      }

      #workspaces button {
          transition: none;
          color: ${theme.base03};
          background: transparent;
          padding: 5px;
          font-size: 18px;
      }

      #workspaces button.persistent {
          color: ${theme.base04};
          font-size: 12px;
      }

      #workspaces button:hover {
          transition: none;
          box-shadow: inherit;
          text-shadow: inherit;
          border-radius: inherit;
          color: ${theme.base00};
          background: ${theme.base03};
      }

      #workspaces button.active {
          background: ${theme.base01};
          color: ${theme.base06};
          border-radius: inherit;
      }

      #keyboard-state {
          margin-right: 8px;
          padding-left: 16px;
          padding-right: 16px;
          border-radius: 10px;
          transition: none;
          color: ${theme.base06};
          background: ${theme.base00};
      }

      #custom-poweroff, #custom-hibernate, #custom-reboot {
          padding-left: 14px;
          margin-right: 8px;
          padding-right: 18px;
          border-radius: 10px;
          transition: none;
          color: ${theme.base06};
          background: ${theme.base00};
      }

      #clock, #pulseaudio, #cpu, #memory, #backlight, #battery, #tray {
          margin-right: 8px;
          padding-left: 16px;
          padding-right: 16px;
          border-radius: 10px;
          transition: none;
          color: ${theme.base06};
          background: ${theme.base00};
      }

      #pulseaudio.muted {
          background-color: ${theme.base0E};
          color: ${theme.base00};
      }

      #battery.charging {
          background-color: ${theme.base0B};
          color: ${theme.base00};
      }

      #battery.warning:not(.charging) {
          background-color: ${theme.base0A};
          color: ${theme.base00};
      }

      #battery.critical:not(.charging) {
          background-color: ${theme.base08};
          color: ${theme.base00};
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      @keyframes blink {
          to {
              background-color: ${theme.base06};
              color: ${theme.base00};
          }
      }
    '';
  };
}
