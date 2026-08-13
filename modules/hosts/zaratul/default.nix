{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.zaratul = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.zaratul
      ./_hardware-configuration.nix
    ];
  };

  flake.nixosModules.zaratul = {pkgs, ...}: {
    imports = [
      inputs.home-manager.nixosModules.default
      self.nixosModules.blank
    ];

    config = {
      users = {
        mutableUsers = false;
      };

      environment.systemPackages = [
        pkgs.vim
        pkgs.firefox
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {inherit inputs;};
      };
    };
  };
}
