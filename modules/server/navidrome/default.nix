{
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        navidrome = {
          enable = lib.mkEnableOption "Enables the navidrome module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.navidrome;
  in
    lib.mkIf cfg.enable {
      services.navidrome = {
        enable = true;
        settings = {
          MusicFolder = "/mnt/music";
        };
      };
    };
}
