{
  flake.nixosModules.grubBoot = {
    lib,
    config,
    ...
  }: {
    options = {
      modules = {
        grub = {
          boot = lib.mkOption {
            default = "single";
            type = lib.types.enum [
              "single"
              "multi"
            ];
          };
        };
      };
    };

    config = let
      cfg = config.modules.grub;
    in {
      boot = {
        consoleLogLevel = 3;

        loader = {
          grub = {
            enable = true;
            device = "nodev";
            useOSProber = cfg.boot == "multi";
            efiSupport = true;
          };

          efi = {
            efiSysMountPoint = "/boot";
            canTouchEfiVariables = true;
          };
        };
      };
    };
  };
}
