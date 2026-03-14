{
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        borg = {
          enable = lib.mkEnableOption "Enables the borg module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.borg;
  in
    lib.mkIf cfg.enable {
      services = {};
    };
}
