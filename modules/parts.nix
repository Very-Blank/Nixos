{lib, ...}: {
  options = {
    flake = {
      userModules = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.functionTo lib.types.deferredModule);
        default = {};
        description = "Nixos modules that take in user name as input.";
      };

      css = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.either (lib.types.functionTo lib.types.str) lib.str);
        default = {};
        description = "Css styles.";
      };

      settings = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.either (lib.types.functionTo lib.types.attrs) lib.types.attrs);
        default = {};
        description = "Settings.";
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
