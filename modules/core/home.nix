{inputs, ...}: {
  flake.nixosModules.home = {...}: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    environment.pathsToLink = ["/share/applications"];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
