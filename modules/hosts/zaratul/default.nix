{self, ...}: {
  flake.nixosConfigurations.zaratul = self.lib.mkNixosSystem {
    modules = [
      self.nixosModules.zaratul
      self.nixosModules.zaratulHardware
    ];
  };

  flake.nixosModules.zaratul = {pkgs, ...}: {
    imports = [
      self.nixosModules.grubBoot
      self.nixosModules.blank
    ];

    features = {
      host = {
        name = "zaratul";
      };

      grub = {
        boot = "multi";
      };
    };

    users = {
      mutableUsers = false;
    };

    environment.systemPackages = [
      pkgs.vim
      pkgs.firefox
    ];

    system.stateVersion = "26.11";
  };
}
