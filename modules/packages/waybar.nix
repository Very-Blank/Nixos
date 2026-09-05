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
    packages.waybar = lib.makeOverridable ({
      font ? {
        package = pkgs.nerd-fonts._0xproto;
        family = "0xProto Nerd Font";
      },
      features ? [
        # "audio"
        # "backlight"
        "system-info"
        # "battery"
        # "tray"
      ],
      leftModules ? ["niri/workspaces"],
    }: let
      config = (pkgs.formats.json {}).generate "config.json" (self.settings.waybar {
        inherit lib;
        inherit pkgs;
        inherit leftModules;
        inherit features;
      });

      style = pkgs.writeText "style.css" (self.css.waybar {
        theme = inputs.colors.lib.withHash self.globals.theme.palette;
        fontFamily = font.family;
        fontWeight = "normal";
      });

      fontConfig = self.lib.mkFontsConf pkgs font.package;
    in (pkgs.symlinkJoin {
      name = "waybar";
      paths = [pkgs.waybar];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--config ${config}"
          "--style ${style}"
        ];
      in
        lib.strings.concatStringsSep " " (
          [
            "wrapProgram $out/bin/waybar"
            "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
          ]
          ++ (
            lib.optional
            (font != null)
            "--set FONTCONFIG_FILE ${fontConfig}"
          )
        );
    })) {};
  };

  flake = {
    homeModules.waybar = {
      lib,
      pkgs,
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
                  "audio"
                  "backlight"
                  "system-info"
                  "battery"
                  "tray"
                ]);
            };
          };
        };
      };

      config = {
        programs.waybar = {
          enable = true;
          package = self.packages.${pkgs.stdenv.hostPlatform.system}.waybar;
        };
      };
    };

    settings.waybar = {
      lib,
      pkgs,
      leftModules,
      features,
    }: let
      enabled = f: (builtins.elem f features);
    in
      {
        layer = "top";
        position = "top";
        margin = "5 10 5 10";
        height = 33;

        modules-center = ["clock"];

        modules-left =
          leftModules
          ++ [
            "keyboard-state"
            "custom/poweroff"
            "custom/hibernate"
            "custom/reboot"
          ];

        modules-right =
          (lib.optional (enabled "audio") "pulseaudio")
          ++ (lib.optional (enabled "backlight") "backlight")
          ++ (lib.optional (enabled "system-info") "memory")
          ++ (lib.optional (enabled "system-info") "cpu")
          ++ (lib.optional (enabled "battery") "battery")
          ++ (lib.optional (enabled "tray") "tray");

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
      }
      // (lib.optionalAttrs (enabled "pulseaudio") {
        "pulseaudio" = {
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
      })
      // (lib.optionalAttrs (enabled "backlight") {
        "backlight" = {
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
      })
      // (lib.optionalAttrs (enabled "system-info") {
        "memory" = {
          interval = 30;
          format = "{}% ";
          tooltip = false;
        };

        "cpu" = {
          interval = 2;
          format = "{usage}% ";
          min-length = 6;
          tooltip = false;
        };
      })
      // (lib.optionalAttrs (enabled "battery") {
        "battery" = {
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
      })
      // (lib.optionalAttrs (enabled "tray") {
        "tray" = {
          icon-size = 20;
          spacing = 10;
          tooltip = false;
        };
      });

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
          padding: 5px;
          font-size: 18px;
          color: ${theme.base03};
          background: transparent;
          transition: none;
      }

      #workspaces button.persistent {
          color: ${theme.base04};
          font-size: 12px;
      }

      #workspaces button:hover {
          border-radius: inherit;
          color: ${theme.base00};
          background: ${theme.base03};
          box-shadow: inherit;
          text-shadow: inherit;
          transition: none;
      }

      #workspaces button.active {
          border-radius: inherit;
          color: ${theme.base06};
          background: ${theme.base01};
      }

      #keyboard-state,
      #clock,
      #pulseaudio,
      #cpu,
      #memory,
      #backlight,
      #battery,
      #tray {
          margin-right: 8px;
          padding-left: 16px;
          padding-right: 16px;
          border-radius: 10px;
          transition: none;
          color: ${theme.base06};
          background: ${theme.base00};
      }

      #custom-poweroff,
      #custom-hibernate,
      #custom-reboot {
          margin-right: 8px;
          padding-left: 14px;
          padding-right: 18px;
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
