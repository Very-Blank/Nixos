{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      desktop = {
        enable = lib.mkEnableOption "Enables the desktop module.";

        windowManager = lib.mkOption {
          default = "niri";
          description = "The enabled window manager.";
          type = lib.types.enum [
            "niri"
            # "sway"
            # "hyprland"
          ];
        };

        terminal = lib.mkOption {
          default = "ghostty";
          description = "The enabled terminal emulator.";
          type = lib.types.enum [
            "ghostty"
          ];
        };

        launcher = lib.mkOption {
          default = "vicinae";
          description = "The enabled launcher.";
          type = lib.types.enum [
            "fuzzel"
            "vicinae"
          ];
        };

        bar = {
          enable = lib.mkEnableOption "Enable the bar.";

          name = lib.mkOption {
            default = "waybar";
            description = "The enabled bar.";
            type = lib.types.enum [
              "waybar"
            ];
          };

          modules = lib.mkOption {
            default = [];
            description = "Extra bar moduels to be enabled.";
            type = with lib.types;
              listOf (enum [
                "systemInfo"
                "tray"
              ]);
          };
        };

        browser = lib.mkOption {
          default = "firefox";
          description = "The enabled browser.";
          type = lib.types.enum [
            "firefox"
          ];
        };

        applications = lib.mkOption {
          default = [];
          description = "Extra apps to be enabled.";
          type = with lib.types;
            listOf (enum [
              "obsidian"
              "nextcloud"
              "obs"
              "steam"
              "mumble"
              "sable"
            ]);
        };
      };
    };
  };

  config = let
    cfg = config.modules.desktop;
  in
    lib.mkIf config.modules.desktop.enable
    {
      environment = {
        systemPackages = [
          pkgs.uwsm
        ];
      };

      modules = {
        tty.greetd = lib.mkIf (cfg.windowManager == "niri") {
          enable = true;
          cmd = lib.mkForce "${pkgs.uwsm}/bin/uwsm start -F -- ${pkgs.niri}/bin/niri --session >/dev/null 2>&1";
        };

        graphical = {
          notifications.mako.enable = lib.mkForce true;

          theming.swaybg.enable = lib.mkForce true;
          theming.gtk.enable = lib.mkForce true;

          launchers.${cfg.launcher}.enable = true;
          terminalEmulators.${cfg.terminal}.enable = lib.mkForce true;

          bars.${cfg.bar.name} = lib.mkMerge [
            (lib.mkIf
              cfg.bar.enable
              {enable = true;})

            (lib.genAttrs
              cfg.bar.modules
              (name: {
                enable = true;
              }))
          ];

          windowManagers.niri = lib.mkIf (cfg.windowManager == "niri") {
            enable = lib.mkForce true;

            spawn-at-startup = [
              {
                command = [
                  "vicinae"
                  "server"
                ];
              }
            ];

            keybinds = with config.userHome.lib.niri.actions; {
              "Mod+D" = lib.mkMerge [
                (lib.mkIf (cfg.launcher == "vicinae") {
                  repeat = false;
                  action = spawn [
                    "vicinae"
                    "toggle"
                  ];
                })
                (lib.mkIf (cfg.launcher == "fuzzel") {
                  action = spawn "${pkgs.fuzzel}/bin/fuzzel";
                })
              ];

              #"å"

              "Mod+T".action = spawn "${pkgs.ghostty}/bin/ghostty";
            };
          };

          applications.browsers.${cfg.browser}.enable = true;

          applications.other = lib.genAttrs cfg.applications (name: {
            enable = true;
          });
        };
      };
    };
}
