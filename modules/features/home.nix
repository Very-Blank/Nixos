{inputs, ...}: {
  flake.nixosModules.home = {...}: {
    environment.pathsToLink = ["/share/applications"];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
