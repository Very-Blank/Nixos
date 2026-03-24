{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options = {
    modules = {
      graphical = {
        windowManagers = {
          niri = {
            enable = lib.mkEnableOption "Enables the niri module.";

            outputs = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    mode = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          width = lib.mkOption {
                            type = lib.types.int;
                            description = "Display width in pixels";
                          };
                          height = lib.mkOption {
                            type = lib.types.int;
                            description = "Display height in pixels";
                          };
                          refresh = lib.mkOption {
                            type = lib.types.float;
                            description = "Refresh rate in Hz";
                          };
                        };
                      };
                      description = "Display mode configuration";
                    };

                    position = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          x = lib.mkOption {
                            type = lib.types.int;
                            description = "Display position in pixels";
                          };
                          y = lib.mkOption {
                            type = lib.types.int;
                            description = "Display position in pixels";
                          };
                        };
                      };
                      description = "Display position configuration";
                    };

                    focus-at-startup = lib.mkEnableOption "Focus on this screen at start up";
                  };
                }
              );

              default = {};
              description = "Monitor output configurations";
              example = {
                "PNP(AOC) 2590G5 0x00002709" = {
                  mode = {
                    width = 1920;
                    height = 1080;
                    refresh = 74.973;
                  };
                };
              };
            };

            spawn-at-startup = lib.mkOption {
              type = lib.types.listOf (
                lib.types.attrTag {
                  argv = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = ''
                      Almost raw process arguments to spawn, without shell syntax.
                      A leading tilde in the zeroth argument will be expanded to the user's home directory. No other preprocessing is applied.
                    '';
                  };
                  sh = lib.mkOption {
                    type = lib.types.str;
                    description = ''
                      A shell command to spawn. Run wild with POSIX syntax.
                    '';
                  };

                  command = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    visible = false;
                  };
                }
              );

              default = [];
            };

            keybinds = let
              rename = name: real:
                lib.mkOptionType {
                  name = "rename";
                  description = "${name}";
                  descriptionClass = "noun";
                  inherit (real) check merge getSubOptions;
                  nestedTypes = {inherit real;};
                };

              optional = type: default: lib.mkOption {inherit type default;};
              nullable = type: optional (lib.types.nullOr type) null;
              attrs = type: optional (lib.types.attrsOf type) {};

              record' = description: options:
                lib.types.submoduleWith {
                  inherit description;
                  shorthandOnlyDefinesConfig = true;
                  modules = [
                    {inherit options;}
                  ];
                };

              attrs-record' = description: opts:
                attrs (
                  if builtins.isFunction opts
                  then
                    lib.types.submoduleWith {
                      inherit description;
                      shorthandOnlyDefinesConfig = true;
                      modules = [
                        (
                          {name, ...}: {
                            options = opts name;
                          }
                        )
                      ];
                    }
                  else record' description opts
                );

              required = type: lib.mkOption {inherit type;};
            in
              attrs-record' "niri keybind" {
                allow-when-locked = optional lib.types.bool false;
                allow-inhibiting = optional lib.types.bool true;
                cooldown-ms = nullable lib.types.int;
                repeat = optional lib.types.bool true;

                hotkey-overlay =
                  optional (lib.types.attrTag {
                    hidden = lib.mkOption {type = lib.types.bool;};
                    title = lib.mkOption {type = lib.types.str;};
                  }) {
                    hidden = false;
                  };

                action = required (rename "niri action" inputs.niri.lib.kdl.types.kdl-leaf);
              };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.graphical.windowManagers.niri;
  in
    lib.mkIf cfg.enable {
      nixpkgs.overlays = [inputs.niri.overlays.niri];
      programs.niri.package = pkgs.niri-stable;

      programs.niri = {
        enable = true;
      };

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;

        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      };

      # FIXME: A lot of this should be in the desktop module.

      environment = {
        variables = {
          NIXOS_OZONE_WL = "1";
        };

        systemPackages = [
          pkgs.xdg-desktop-portal
          pkgs.xdg-desktop-portal-gnome
          pkgs.nautilus

          pkgs.wayland-utils
          pkgs.xwayland-satellite-unstable

          pkgs.wtype
          pkgs.wl-clipboard
          pkgs.libsecret
          pkgs.cage
          pkgs.gamescope
        ];
      };

      userHome = let
        cursorName = "Bibata-Original-Classic";
        cursorSize = 16;
      in {
        home = {
          pointerCursor = {
            name = cursorName;
            package = pkgs.bibata-cursors;
            size = cursorSize;
            gtk.enable = true;
            x11.enable = true;
          };

          sessionVariables = {
            XCURSOR_THEME = cursorName;
            XCURSOR_SIZE = toString cursorSize;
          };
        };

        programs.niri = {
          settings = {
            outputs = cfg.outputs;

            input = {
              keyboard = {
                repeat-delay = 150;
              };
            };

            hotkey-overlay = {
              skip-at-startup = true;
            };

            cursor = {
              theme = cursorName;
              size = cursorSize;
            };

            screenshot-path = "~/Pictures/Screenshots/Screenshot%Y_%m_%d_%H_%M_%S.png";

            prefer-no-csd = true;

            spawn-at-startup =
              [
                {command = ["xwayland-satellite"];}
              ]
              ++ cfg.spawn-at-startup;

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

            # FIXME: Some of these should be only added if the underlying package is added.
            window-rules = [
              {
                draw-border-with-background = false;
                geometry-corner-radius = let
                  radius = 4.0;
                in {
                  top-left = radius;
                  top-right = radius;
                  bottom-left = radius;
                  bottom-right = radius;
                };
                clip-to-geometry = true;
              }

              {
                matches = [
                  {
                    app-id = "^firefox$";
                    title = "^Picture-in-Picture$";
                  }
                ];
                open-floating = true;
              }

              {
                matches = [{app-id = "^\\.blueman-manager-wrapped$";}];
                open-floating = true;
                max-width = 600;
                min-width = 600;
                max-height = 400;
                min-height = 400;
              }

              {
                matches = [{app-id = "^nm-connection-editor$";}];
                open-floating = true;
              }
            ];

            binds = with config.userHome.lib.niri.actions; let
              sh = spawn "sh" "-c";
            in
              lib.mkMerge [
                {
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
                  "Mod+Shift+F".action = fullscreen-window;

                  "Mod+C".action = center-column;
                  "Mod+V".action = toggle-window-floating;

                  "Mod+Shift+S".action.screenshot = [];
                  "Print".action.screenshot-screen = [];

                  "Mod+Q".action = close-window;
                  "Mod+Shift+E".action = quit;

                  "Mod+Semicolon".action = spawn [
                    "wtype"
                    "ö"
                  ];

                  "Mod+Apostrophe".action = spawn [
                    "wtype"
                    "ä"
                  ];

                  "Mod+Shift+Semicolon".action = spawn [
                    "wtype"
                    "Ö"
                  ];

                  "Mod+Shift+Apostrophe".action = spawn [
                    "wtype"
                    "Ä"
                  ];
                }

                (lib.mkIf config.modules.hardware.audio.enable {
                  "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                  "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                  "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                })

                cfg.keybinds
              ];
          };
        };
      };
    };
}
