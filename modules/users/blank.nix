{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {...}: {
        imports =
          [
            self.nixosModules.steam
            self.nixosModules.niri
          ]
          ++ (map (module: self.combinedModules."${module}" user)
            ["zsh"]);

        core = {
          unfree = {
            packages = [
              "obsidian"
            ];
          };
        };

        users.users."${user}" = {
          extraGroups = [
            "wheel"
            "video"
            "input"
            "audio"
          ];
        };
      };

      homeModule = user: {
        lib,
        pkgs,
        ...
      }: {
        imports = with self.homeModules; [
          greeter
          gtk
          networkingTray
          bluetoothTray
          firefox
          nvim
          obs
        ];

        services = {
          nextcloud-client = {
            enable = true;
          };
        };

        modules = {
          greeter = {
            cmd = "${lib.getExe' (self.packages.niri.override {
              niri = let
                launcher = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun "anyrun"}";
              in {
                audio = true;
                brightness = true;
                terminal = "${lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty "ghostty"}";
                inherit launcher;

                screenshots = {
                  path = "~/Pictures/Screenshots/";
                  format = "screenshot_%Y-%m-%d_%Hh%Mm%Ss.png";
                };

                spawnAtStartUp = [
                  [
                    "${lib.getExe' (self.packages.${pkgs.stdenv.hostPlatform.system}.waybar.override {
                      features = [
                        "tray"
                        "audio"
                        "system-info"
                        "backlight"
                        "battery"
                      ];
                    }) "waybar"}"
                  ]
                  [
                    launcher
                    "daemon"
                  ]
                ];
              };
            }) "niri"}";
          };
        };

        xdg = {
          enable = true;

          userDirs = {
            createDirectories = true;
          };
        };

        programs = {
          git = {
            enable = true;

            settings = {
              init = {
                defaultBranch = "main";
              };

              user = {
                name = "very-blank";
                email = "aapeli.saarelainen.76@gmail.com";
              };
            };
          };
        };

        home = {
          packages = [pkgs.obsidian];
          stateVersion = "26.11";
        };
      };
    };
  };
}
