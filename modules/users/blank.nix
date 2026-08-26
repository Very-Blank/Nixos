{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {...}: {
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
