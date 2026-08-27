{
  flake = {
    nixosModules.unfree = {
      lib,
      config,
      ...
    }: {
      options = {
        features = {
          unfree = {
            packages = lib.mkOption {
              type = with lib.types; listOf nonEmptyStr;
              default = [];
              description = "Packages that are unfree that should be allowed.";
            };
          };
        };
      };

      config = let
        cfg = config.features.unfree;
      in {
        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.packages;
      };
    };
  };
}
