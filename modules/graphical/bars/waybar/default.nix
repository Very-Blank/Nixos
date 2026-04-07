{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      graphical = {
        bars = {
          waybar = {
            enable = lib.mkEnableOption "Enables the waybar module.";

            tray = {
              enable = lib.mkEnableOption "System tray.";
            };

            systemInfo = {
              enable = lib.mkEnableOption "System info.";
            };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.graphical.bars.waybar;
  in
    lib.mkIf cfg.enable {
      fonts = {
        packages = [
          pkgs.nerd-fonts._0xproto
        ];
      };

      modules.graphical.theming = {
        icons.enable = lib.mkIf cfg.tray.enable true;
      };

      programs = {
        waybar = {
          enable = true;
        };
      };

      userHome = {
        programs.waybar = {
          enable = true;
          style = import ./style.nix {
            theme = config.colors.palette;
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
                (lib.mkIf config.modules.graphical.windowManagers.niri.enable ["niri/workspaces"])
                [
                  "keyboard-state"
                  "custom/poweroff"
                  "custom/hibernate"
                  "custom/reboot"
                ]
              ];

              modules-right = lib.mkMerge [
                (lib.mkIf config.modules.hardware.audio.enable ["pulseaudio"])
                (lib.mkIf config.modules.hardware.backlight.enable ["backlight"])
                (lib.mkIf cfg.systemInfo.enable [
                  "memory"
                  "cpu"
                ])
                (lib.mkIf config.modules.hardware.info.battery ["battery"])
                (lib.mkIf cfg.tray.enable ["tray"])
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

              "pulseaudio" = lib.mkIf config.modules.hardware.audio.enable {
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
                on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
                min-length = 13;
                tooltip = false;
              };

              "memory" = lib.mkIf cfg.systemInfo.enable {
                interval = 30;
                format = "{}% ";
                tooltip = false;
              };

              "cpu" = lib.mkIf cfg.systemInfo.enable {
                interval = 2;
                format = "{usage}% ";
                min-length = 6;
                tooltip = false;
              };

              "backlight" = lib.mkIf config.modules.hardware.backlight.enable {
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

              "battery" = lib.mkIf config.modules.hardware.info.battery {
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

              "tray" = lib.mkIf cfg.tray.enable {
                icon-size = 20;
                spacing = 10;
                tooltip = false;
              };
            };
          };
        };
      };
    };
}
