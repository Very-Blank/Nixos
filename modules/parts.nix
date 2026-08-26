{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  options = {
    flake = {
      combinedModules = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.functionTo lib.types.deferredModule);
        default = {};
        description = "Modules that combined home and nixos modules into one.";
      };
    };
  };

  config = {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
