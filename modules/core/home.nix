{inputs, ...}: {
  flake.nixosModules.home = {...}: {
    imports = [
      inputs.home-manager.nixosModules.default
    ];

    environment.pathsToLink = ["/share/applications"];

    programs.dconf.enable = true;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs;};
    };
  };
}
