{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {
        lib,
        config,
        options,
        ...
      }: {
        imports =
          [self.nixosModules.steam]
          ++ (map (module: self.combinedModules."${module}" user)
            ["niri" "firefox" "zsh" "obsidian"]);

        config =
          {
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
          }
          // (lib.optionalAttrs (options ? modules.greeter) {
            modules = {
              greeter = {
                commands = [
                  {
                    inherit user;
                    cmd = "${lib.getExe' config.home-manager.users."${user}".wayland.windowManager.niri.package "niri"}";
                  }
                ];
              };
            };
          });
      };

      homeModule = user: {...}: {
        imports = [
          self.homeModules.nvim
          self.homeModules.obs
        ];

        xdg = {
          enable = true;

          userDirs = {
            createDirectories = true;
          };
        };

        services = {
          nextcloud-client = {
            enable = true;
          };
        };

        home = {
          stateVersion = "26.11";
        };
      };
    };
  };
}
