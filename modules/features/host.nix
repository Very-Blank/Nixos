{
  flake = {
    nixosModules.host = {lib, ...}: {
      options = {
        features = {
          host = {
            name = lib.mkOption {
              default = "nixos";
              description = "The systems/hosts name.";
              type = lib.types.nonEmptyStr;
            };
          };
        };
      };
    };
  };
}
