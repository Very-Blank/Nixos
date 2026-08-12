{
  lib,
  # self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    lib,
    # system,
    # self',
    ...
  }: {
    packages.niri = lib.makeOverridable ({
      terminal ? null,
      launcher ? null,
      screenshotPath ? null,
      audio ? false,
      brightness ? false,
      cursor ? null,
    }: let
      config =
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

          spawn-at-startup = [
            ["${lib.getExe pkgs.xwayland-satellite}"]
          ];

          environment = {
            DISPLAY = ":0";
          };

          layout = {
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
              active-gradient._props = {
                to = "rgb(255 200 255)";
                from = "rgb(120 000 200)";
                angle = 45;
              };

              inactive-color = "rgb(127 200 255)";
            };

            tab-indicator = {
              width = 4;
              gap = 4;
              position = "top";
              place-within-column = true;

              active-gradient._props = {
                to = "rgb(127 200 255)";
                from = "rgb(120 000 200)";
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
            // (lib.optionalAttrs (terminal != null) {
              "Mod+T" = {spawn = "${lib.getExe terminal}";};
            })
            // (lib.optionalAttrs (launcher != null) {
              "Mod+D" = {spawn = "${lib.getExe launcher}";};
            })
            // (lib.optionalAttrs (screenshotPath != null) {
              "Mod+Shift+S" = {screenshot = [];};
              "Print" = {screenshot-screen = [];};
            })
            // (lib.optionalAttrs audio {
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
            // (lib.optionalAttrs brightness {
              "XF86MonBrightnessUp" = {
                spawn = ["${lib.getExe pkgs.brightnessctl}" "set" "5%+"];
              };
              "XF86MonBrightnessDown" = {
                spawn = ["${lib.getExe pkgs.brightnessctl}" "set" "5%-"];
              };
            });
        }
        // (lib.optionalAttrs (screenshotPath != null) {
          screenshot-path = screenshotPath;
        })
        // lib.optionalAttrs (cursor != null) {
          cursor = {
            xcursor-theme = cursor.theme;
            xcursor-size = cursor.size;
          };
        };

      kdlConfig = inputs.niri.lib.validatedConfigFor pkgs.niri (inputs.niri.lib.mkNiriKDL config);
    in (pkgs.symlinkJoin {
      name = "niri";
      paths = [pkgs.niri];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/niri --add-flags "--config ${kdlConfig}"
      '';
    })) {};
  };

  flake = {
    combinedModule.niri = user:
      assert builtins.isString user;
        {
          self,
          pkgs,
          # inputs,
          ...
        }: {...}: {
          environment = {
            variables = {
              NIXOS_OZONE_WL = "1";
            };

            systemPackages = [
              pkgs.wayland-utils
              pkgs.wl-clipboard-rs
              pkgs.libsecret
            ];
          };

          xdg.portal = {
            xdgOpenUsePortal = true;
            extraPortals = pkgs.xdg-desktop-portal-gtk;
          };

          home-manager.users.${user} = let
            cursor = {
              theme = "Bibata-Modern-Classic";
              size = 12;
            };
          in {
            programs.niri = {
              enable = true;
              package = self.packages.${pkgs.stdenv.hostPlatform.system}.niri.override {
                screenshotPath = "~/Pictures/Screenshots/Screenshot%H_%M_%S_%d%m%Y.png";
                audio = true;
                brightness = true;
                inherit cursor;
              };
            };

            home = {
              pointerCursor = {
                name = cursor.theme;
                package = pkgs.bibata-cursors;
                size = cursor.size;
                gtk.enable = true;
                x11.enable = true;
              };

              sessionVariables = {
                XCURSOR_THEME = cursor.theme;
                XCURSOR_SIZE = toString cursor.size;
              };
            };
          };
        };
  };
}
