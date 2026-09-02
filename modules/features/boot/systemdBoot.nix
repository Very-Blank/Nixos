{
  flake.nixosModules.systemdBoot = {...}: {
    boot = {
      consoleLogLevel = 3;
      loader = {
        efi = {
          canTouchEfiVariables = true;
        };

        systemd-boot = {
          enable = true;
        };
      };
    };
  };
}
