{self, ...}: {
  flake.nixosModules.systemdBoot = {...}: {
    imports = [self.nixosModules.boot];

    boot.loader.systemd-boot.enable = true;
  };
}
