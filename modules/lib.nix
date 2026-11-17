{
  lib,
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
              self.nixosModules.preservation
              self.nixosModules.defaults
              self.nixosModules.host
              self.nixosModules.unfree
              self.nixosModules.greeter
              self.nixosModules.boot
              self.nixosModules.services
              inputs.hjem.nixosModules.default
              ({...}: {
                security.sudo.extraConfig = ''
                  Defaults lecture="never"
                '';
              })
            ]
            ++ modules;
        };

      evalConfig = pkgs: options: module: let
        cfg =
          (lib.evalModules {
            modules = [
              {
                options = {
                  assertions = lib.mkOption {
                    type = lib.types.listOf lib.types.unspecified;
                    internal = true;
                    default = [];
                    example = [
                      {
                        assertion = false;
                        message = "reason";
                      }
                    ];
                  };
                  warnings = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    internal = true;
                    default = [];
                  };
                };

                config = {
                  _module.args = {
                    pkgs = pkgs;
                  };
                };
              }
              options
              module
            ];
          }).config;
      in
        lib.asserts.checkAssertWarn cfg.assertions cfg.warnings cfg;
    };
  };
}
