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
              inputs.sops-nix.nixosModules.sops
              self.nixosModules.host
              self.nixosModules.home
              self.nixosModules.unfree
              {
                sops = {
                  age.keyFile = "/var/lib/sops/age/keys.txt";
                };
              }
            ]
            ++ modules;
        };

      mkCombinedModule = {
        nixosModule,
        homeModule,
      }: user:
        assert builtins.isString user;
          {...}: {
            imports = [(nixosModule user)];

            config = {
              home-manager.users."${user}" = homeModule user;
            };
          };

      mkUserModule = user:
        assert builtins.isString user;
          {
            nixosModule,
            homeModule,
          }: {...}: {
            imports = [(nixosModule user)];

            config = {
              home-manager.users."${user}" = {
                imports = [
                  inputs.sops-nix.homeManagerModules.sops
                  (homeModule user)
                ];
              };
            };
          };

      mkFontsConf = pkgs: fontPackage:
        pkgs.writeText "fonts.conf" ''
          <?xml version='1.0'?>
          <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
          <fontconfig>
            <dir>${fontPackage}</dir>
            <cachedir>/var/cache/fontconfig</cachedir>
            <cachedir prefix="xdg">fontconfig</cachedir>
          </fontconfig>
        '';
    };
  };
}
