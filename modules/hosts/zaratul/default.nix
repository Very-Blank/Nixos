{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.zaratul = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zaratul
      self.nixosModules.zaratulHardware
    ];
  };

  flake.nixosModules.zaratul = {pkgs, ...}: {
    imports = [
      self.nixosModules.home
      self.nixosModules.grubBoot
      self.nixosModules.blank
    ];

    features.grub.boot = "multi";

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
