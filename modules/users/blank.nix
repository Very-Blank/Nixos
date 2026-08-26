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
          map (module: self.combinedModules."${module}" user)
          ["niri" "firefox" "zsh"];

        users.users."${user}" = {
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
                cmd = "${lib.getExe config.home-manager.users."${user}".wayland.windowManager.niri.package}";
              }
            ];
          };
        };
      };

      homeModule = user: {...}: {
        imports = [
          self.homeModules.nvim
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
