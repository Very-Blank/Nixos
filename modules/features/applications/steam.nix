{...}: {
  flake = {
    nixosModules.steam = {...}: {
      programs.steam = {
        enable = true;
      };

      core.unfree.packages = [
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
    };
  };
}
