{
  flake = {
    nixosModules.battery = {
      services = {
        upower.enable = true;
        power-profiles-daemon.enable = true;
      };

      core = {
        host = {
          features = [
            "battery"
          ];
        };
      };
    };
  };
}
