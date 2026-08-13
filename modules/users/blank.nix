{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {pkgs, ...}: {
        imports = [(self.combinedModules.niri user)];

        config = {
          users.users."${user}" = {
            shell = pkgs.zsh;

            isNormalUser = true;

            extraGroups = [
              "wheel"
              "video"
              "input"
              "audio"
            ];
          };
        };
      };

      homeModule = user: {...}: {
        xdg = {
          enable = true;
          userDirs.createDirectories = true;
        };

        home = {
          stateVersion = "26.05";
        };
      };
    };
  };
}
