{...}: {
  flake = {
    nixosModules.steam = {pkgs, ...}: {
      programs.steam = {
        enable = true;

        package = pkgs.steam.override {
          extraEnv = {
            PROTON_ENABLE_WAYLAND = "1";
          };

          extraCompatPackages = [pkgs.proton-ge-bin];
        };
      };

      core.unfree.packages = [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
    };

    userModules.steamPersistent = user: {
      preservation = {
        preserveAt."/persistent" = {
          users.${user} = {
            directories = [
              ".local/share/Steam"
              ".steam"
            ];
          };
        };
      };
    };
  };
}
