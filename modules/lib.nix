{
  self,
  inputs,
  ...
}: {
  flake = {
    lib = {
      mkNixosSystem = {modules ? []}:
        inputs.nixpkgs.lib.nixosSystem {
          modules =
            [
              self.nixosModules.sops
              self.nixosModules.disko
              self.nixosModules.perservation
              self.nixosModules.host
              self.nixosModules.home
              self.nixosModules.unfree
              inputs.hjem.nixosModules.default
              ({...}: {
                security.sudo.extraConfig = ''
                  Defaults lecture="never"
                '';
              })
            ]
            ++ modules;
        };
    };
  };
}
