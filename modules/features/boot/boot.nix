{...}: {
  flake.nixosModules.boot = {...}: {
    boot = {
      consoleLogLevel = 3;
      loader.efi.canTouchEfiVariables = true;
    };
  };
}
