{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      graphical = {
        applications = {
          other = {
            mumble = {
              enable = lib.mkEnableOption "Enables the mumble module.";
            };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.graphical.applications.other.mumble;
  in
    lib.mkIf cfg.enable {
      userHome = {
        home.packages = [pkgs.mumble];
      };
    };
}
