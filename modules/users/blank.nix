{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {
        lib,
        config,
        options,
        ...
      }: {
        assertions = [
          {
            assertion = options ? features.greeter;
            message = "The user ${user} relies on the greeter nixos module.";
          }
        ];

        imports =
          [self.nixosModules.steam]
          ++ (map (module: self.combinedModules."${module}" user)
            ["niri" "firefox" "zsh" "obsidian"]);

        sops.secrets."users/${user}/password-hash" = {
          sopsFile = ../../../secrets/users/. + "./${user}.yaml";
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

        features = {
          greeter = {
            commands = [
              {
                inherit user;
                cmd = "${lib.getExe' config.home-manager.users."${user}".wayland.windowManager.niri.package "niri"}";
              }
            ];
          };
        };
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

        home = {
          stateVersion = "26.11";
        };
      };
    };
  };
}
