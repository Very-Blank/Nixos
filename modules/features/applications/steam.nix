{...}: {
  flake = {
    nixosModules.steam = {...}: {
      programs.steam = {
        enable = true;
      };

      features.unfree.packages = [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
    };
  };
}
