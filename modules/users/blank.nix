{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {config, ...}: {
        imports =
          [self.nixosModules.steam]
          ++ (map (module: self.combinedModules."${module}" user)
            ["niri" "zsh"]);

        core = {
          unfree = {
            packages = [
              "obsidian"
            ];
          };
        };

        sops.secrets."users/${user}/password-hash" = {
          sopsFile = ../../secrets/users/. + "/${user}.yaml";
          neededForUsers = true;
        };

        users.users."${user}" = {
          hashedPasswordFile = config.sops.secrets."users/${user}/password-hash".path;

          isNormalUser = true;

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
        config,
        ...
      }: {
        imports = with self.homeModules; [
          greeter
          gtk
          waybar
          networkingTray
          bluetoothTray
          vicinae
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
          niri = {
            audio = true;
            brightness = true;
            terminal = "${lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty "ghostty"}";
            launcher = "${lib.getExe config.programs.vicinae.package}";
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
                }) "ghostty"}"
              ]
            ];
          };

          greeter = {
            cmd = "${lib.getExe' config.wayland.windowManager.niri.package "niri"}";
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
