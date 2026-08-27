{self, ...}: {
  flake.nixosModules.grubBoot = {
    lib,
    config,
    ...
  }: {
    imports = [self.nixosModules.boot];

    options = {
      features = {
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

    config = {
      boot.loader = {
        grub = {
          enable = true;
          device = "nodev";
          useOSProber = config.features.grub.boot == "multi";
          efiSupport = true;
        };

        efi.efiSysMountPoint = "/boot";
      };
    };
  };
}
