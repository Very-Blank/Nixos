{
  self,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    inputs',
    ...
  }: {
    packages.niri = lib.makeOverridable (module: let
      niri-package = inputs'.niri.packages.niri;
      cfg = self.lib.evalConfig pkgs self.configOptions.niri module;

      kdlConfig = inputs.niri-nix.lib.validatedConfigFor niri-package (inputs.niri-nix.lib.mkNiriKDL (self.settings.niri {
        inherit lib;
        inherit pkgs;
        inherit cfg;
      }));

      niriService = pkgs.writeText "niri.service" ''
        [Unit]
        Description=A scrollable-tiling Wayland compositor
        BindsTo=graphical-session.target
        Before=graphical-session.target
        Wants=graphical-session-pre.target
        After=graphical-session-pre.target

        Wants=xdg-desktop-autostart.target
        Before=xdg-desktop-autostart.target

        [Service]
        Slice=session.slice
        Type=notify
        ExecStart=@niri@ --session
      '';

      cursorTheme = pkgs.writeTextDir "share/icons/default/index.theme" ''
        [Icon Theme]
        Name=Default
        Comment=Default cursor theme
        Inherits=${cfg.cursor.theme}
      '';
    in (pkgs.symlinkJoin {
      name = "niri";
      paths = [niri-package];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/niri --add-flags "--config ${kdlConfig}" \
            --set NIXOS_OZONE_WL 1 \
            --set XCURSOR_PATH ${cursorTheme}/share/icons:${cfg.cursor.package}/share/icons \
            --set XCURSOR_THEME ${cfg.cursor.theme} \
            --set XCURSOR_SIZE ${toString cfg.cursor.size}

        rm "$out/share/systemd/user/niri.service"

        substitute "${niriService}" "$out/share/systemd/user/niri.service" --replace-fail '@niri@' "$out/bin/niri"
      '';

      meta.mainProgram = "niri";
    })) {};
  };

  flake = {
    nixosModules.niri = {pkgs, ...}: {
      environment = {
        pathsToLink = [
          "/share/xdg-desktop-portal"
        ];

        systemPackages = [
          pkgs.wayland-utils
          pkgs.wl-clipboard-rs
          pkgs.libsecret
        ];
      };

      services = {
        gnome = {
          gnome-keyring = {
            enable = true;
          };
        };

        dbus = {
          packages = [
            pkgs.nautilus
          ];
        };
      };

      xdg.portal = {
        xdgOpenUsePortal = true;

        extraPortals = [
          pkgs.xdg-desktop-portal-gnome
        ];
      };
    };

    configOptions.niri = {
      lib,
      pkgs,
      ...
    }: {
      options = {
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

                scale = lib.mkOption {
                  type = lib.types.float;
                  default = 1.0;
                };

                position = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      x = lib.mkOption {
                        type = lib.types.int;
                        description = "Display position in pixels";
                        default = 0;
                      };
                      y = lib.mkOption {
                        type = lib.types.int;
                        description = "Display position in pixels";
                        default = 0;
                      };
                    };
                  };
                  description = "Display position configuration";
                };

                main = lib.mkEnableOption "Main output.";
              };
            }
          );

          default = {};
        };

        cursor = lib.mkOption {
          type = lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
              };

              theme = lib.mkOption {
                type = lib.types.nonEmptyStr;
              };

              size = lib.mkOption {
                type = lib.types.int;
              };
            };
          };

          default = {
            package = pkgs.bibata-cursors;
            theme = "Bibata-Modern-Classic";
            size = 13;
          };
        };

        terminal = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
        };

        launcher = lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
        };

        audio = lib.mkEnableOption ''
          Enables audio controll keybinds using wireplumber's wpctl tool.
        '';

        brightness = lib.mkEnableOption ''
          Enables brightness controll keybinds using brightnessctl.
        '';

        screenshots = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.nonEmptyStr;
                example = "~/Pictures/Screenshots/";
              };

              format = lib.mkOption {
                type = lib.types.nonEmptyStr;
                example = "screenshot_%Y-%m-%d_%Hh%Mm%Ss.png";
              };
            };
          });

          default = null;
        };

        spawnAtStartUp = lib.mkOption {
          type = lib.types.listOf (lib.types.listOf lib.types.nonEmptyStr);
        };
      };
    };

    settings.niri = {
      lib,
      pkgs,
      cfg,
    }:
      {
        input = {
          keyboard = {
            repeat-delay = 150;
          };
        };

        hotkey-overlay = {
          skip-at-startup = true;
        };

        prefer-no-csd = true;

        spawn-at-startup = cfg.spawnAtStartUp;

        xwayland-satellite = {
          path = "${lib.getExe pkgs.xwayland-satellite}";
        };

        cursor = {
          hide-when-typing = true;
          xcursor-theme = cfg.cursor.theme;
          xcursor-size = cfg.cursor.size;
        };

        input = {
          touchpad = {
            tap = [];
            natural-scroll = [];
            dwt = [];
          };
        };

        window-rule = {
          geometry-corner-radius = 4;
          clip-to-geometry = true;
        };

        layout = let
          palette = inputs.colors.lib.withHash self.globals.theme.palette;
        in {
          gaps = 8;
          center-focused-column = "never";

          preset-column-widths._children = [
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
          ];

          default-column-width = {
            proportion = 1.0 / 2.0;
          };

          focus-ring = {
            width = 3;

            active-gradient._props = {
              to = "${palette.base0E}";
              from = "${palette.base0D}";
              angle = 45;
            };

            inactive-color = "${palette.base04}";
          };

          tab-indicator = {
            width = 4;
            gap = 2;
            position = "top";
            place-within-column = true;

            active-gradient._props = {
              to = "${palette.base04}";
              from = "${palette.base0D}";
              angle = 45;
            };
          };
        };

        binds =
          {
            "Mod+H" = {focus-column-left = [];};
            "Mod+J" = {focus-window-down = [];};
            "Mod+K" = {focus-window-up = [];};
            "Mod+L" = {focus-column-right = [];};

            "Mod+Shift+H" = {move-column-left = [];};
            "Mod+Shift+J" = {move-window-down = [];};
            "Mod+Shift+K" = {move-window-up = [];};
            "Mod+Shift+L" = {move-column-right = [];};

            "Mod+Ctrl+H" = {focus-monitor-left = [];};
            "Mod+Ctrl+J" = {focus-monitor-down = [];};
            "Mod+Ctrl+K" = {focus-monitor-up = [];};
            "Mod+Ctrl+L" = {focus-monitor-right = [];};

            "Mod+Shift+Ctrl+H" = {move-column-to-monitor-left = [];};
            "Mod+Shift+Ctrl+J" = {move-column-to-monitor-down = [];};
            "Mod+Shift+Ctrl+K" = {move-column-to-monitor-up = [];};
            "Mod+Shift+Ctrl+L" = {move-column-to-monitor-right = [];};

            "Mod+Minus" = {set-column-width = "-10%";};
            "Mod+Equal" = {set-column-width = "+10%";};
            "Mod+Shift+Minus" = {set-window-height = "-10%";};
            "Mod+Shift+Equal" = {set-window-height = "+10%";};

            "Mod+R" = {switch-preset-column-width = [];};
            "Mod+F" = {maximize-column = [];};
            "Mod+Shift+F" = {fullscreen-window = [];};

            "Mod+C" = {center-column = [];};
            "Mod+V" = {toggle-window-floating = [];};

            "Mod+Q" = {close-window = [];};
            "Mod+Shift+E" = {quit = [];};

            "Mod+Semicolon" = {
              spawn = [
                "${lib.getExe pkgs.wtype}"
                "ö"
              ];
            };

            "Mod+Apostrophe" = {
              spawn = [
                "${lib.getExe pkgs.wtype}"
                "ä"
              ];
            };

            "Mod+Shift+Semicolon" = {
              spawn = [
                "${lib.getExe pkgs.wtype}"
                "Ö"
              ];
            };

            "Mod+Shift+Apostrophe" = {
              spawn = [
                "${lib.getExe pkgs.wtype}"
                "Ä"
              ];
            };
          }
          // (lib.listToAttrs (map (num: {
            name = "Mod+${toString num}";
            value.focus-workspace = num;
          }) (lib.range 1 9)))
          // (lib.optionalAttrs (cfg.terminal != null) {
            "Mod+T" = {spawn = "${cfg.terminal}";};
          })
          // (lib.optionalAttrs (cfg.launcher != null) {
            "Mod+D" = {spawn = "${cfg.launcher}";};
          })
          // (lib.optionalAttrs (cfg.screenshots != null) {
            "Mod+Shift+S" = {screenshot = [];};
            "Print" = {screenshot-screen = [];};
          })
          // (lib.optionalAttrs cfg.audio {
            "XF86AudioRaiseVolume" = {
              spawn = ["${lib.getExe' pkgs.wireplumber "wpctl"}" "set-volume" "@DEFAULT_AUDIO_SINK@" " 0.1+"];
            };
            "XF86AudioLowerVolume" = {
              spawn = ["${lib.getExe' pkgs.wireplumber "wpctl"}" "set-volume" "@DEFAULT_AUDIO_SINK@" " 0.1+"];
            };
            "XF86AudioMute" = {
              spawn = ["${lib.getExe' pkgs.wireplumber "wpctl"}" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
            };
          })
          // (lib.optionalAttrs cfg.brightness {
            "XF86MonBrightnessUp" = {
              spawn = ["${lib.getExe pkgs.brightnessctl}" "set" "5%+"];
            };
            "XF86MonBrightnessDown" = {
              spawn = ["${lib.getExe pkgs.brightnessctl}" "set" "5%-"];
            };
          });
      }
      // (lib.optionalAttrs (cfg.screenshots != null) {
        screenshot-path = "${cfg.screenshots.path}${cfg.screenshots.format}";
      })
      // (
        lib.optionalAttrs (cfg.outputs != {})
        {
          output =
            lib.mapAttrsToList (
              name: settings: ({
                  _args = [name];

                  mode = "${lib.toString settings.mode.width}x${lib.toString settings.mode.height}@${lib.toString settings.mode.refresh}";

                  position._props = {
                    x = settings.position.x;
                    y = settings.position.y;
                  };

                  scale = settings.scale;
                }
                // lib.optionalAttrs settings.main {
                  focus-at-startup = [];
                })
            )
            cfg.outputs;
        }
      );
  };
}
