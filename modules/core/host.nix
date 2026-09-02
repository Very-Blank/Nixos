{
  flake = {
    nixosModules.host = {lib, ...}: {
      options = {
        core = {
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
