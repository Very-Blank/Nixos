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

            type = lib.mkOption {
              type = lib.types.enum [
                "live"
                "vm"
              ];
              description = "Is the system a VM or not.";
              default = "live";
            };

            features = lib.mkOption {
              type = lib.types.listOf (lib.types.enum [
                "battery"
                "bluetooth"
                "wifi"
              ]);
              description = "What features does the host have.";
              default = [];
            };
          };
        };
      };
    };
  };
}
