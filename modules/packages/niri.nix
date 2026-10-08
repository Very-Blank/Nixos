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
    packages.niri = lib.makeOverridable ({
      spawnAtStartUp ? [],
      terminal ? null,
      launcher ? null,
      screenshots ? null,
      audio ? false,
      brightness ? false,
      cursor ? {
        package = pkgs.bibata-cursors;
        theme = "Bibata-Modern-Classic";
        size = 12;
      },
    }: let
      kdlConfig = inputs.niri.lib.validatedConfigFor pkgs.niri (inputs.niri.lib.mkNiriKDL (self.settings.niri {
        inherit lib;
        inherit pkgs;
        inherit spawnAtStartUp;
        inherit terminal;
        inherit launcher;
        inherit screenshots;
        inherit audio;
        inherit brightness;
        inherit cursor;
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
    in (pkgs.symlinkJoin {
      name = "niri";
      paths = [pkgs.niri cursor.package];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/niri --add-flags "--config ${kdlConfig}" --set XCURSOR_PATH ${cursor.package}/share/icons

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
    };

    settings.niri = {
      lib,
      pkgs,
      spawnAtStartUp ? [],
      terminal ? null,
      launcher ? null,
      screenshots ? null,
      audio ? false,
      brightness ? false,
      cursor ? null,
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

        spawn-at-startup =
          [
            ["${lib.getExe pkgs.xwayland-satellite}"]
          ]
          ++ spawnAtStartUp;

        environment =
          {
            DISPLAY = ":0";
          }
          # FIXME: This might be unneeded.
          // lib.optionalAttrs (cursor != null) {
            XCURSOR_PATH = "${cursor.package}/share/icons";
          };

        cursor =
          {
            hide-when-typing = true;
          }
          // lib.optionalAttrs (cursor != null) {
            xcursor-theme = cursor.theme;
            xcursor-size = cursor.size;
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
            active-gradient._props = {
              to = "${palette.base0E}";
              from = "${palette.base0D}";
              angle = 45;
            };

            inactive-color = "${palette.base04}";
          };

          tab-indicator = {
            width = 4;
            gap = 4;
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
          // (lib.optionalAttrs (terminal != null) {
            "Mod+T" = {spawn = "${terminal}";};
          })
          // (lib.optionalAttrs (launcher != null) {
            "Mod+D" = {spawn = "${launcher}";};
          })
          // (lib.optionalAttrs (screenshots != null) {
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
      // (lib.optionalAttrs (screenshots != null) {
        screenshot-path = "${screenshots.path}${screenshots.format}";
      });
  };
}
