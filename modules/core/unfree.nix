{
  flake = {
    nixosModules.unfree = {
      lib,
      config,
      ...
    }: {
      options = {
        core = {
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
        cfg = config.core.unfree;
      in {
        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.packages;
      };
    };
  };
}
