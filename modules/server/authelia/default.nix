{
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        authelia = {
          enable = lib.mkEnableOption "Enables the authelia module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.authelia;
  in
    lib.mkIf cfg.enable {};
}
