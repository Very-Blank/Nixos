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
            sable = {
              enable = lib.mkEnableOption "Enables the sable module.";
            };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.graphical.applications.other.sable;
  in
    lib.mkIf cfg.enable {
      userHome = {
        home.packages = [pkgs.sable];
      };
    };
}
