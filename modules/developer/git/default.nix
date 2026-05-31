{
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      developer = {
        git = {
          enable = lib.mkEnableOption "Enable the git module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.developer.git;
  in
    lib.mkIf cfg.enable {
      userHome = {
        programs.git = {
          enable = true;

          ignores = [
            "dev.nix"
          ];

          settings = {
            init.defaultBranch = "main";

            user = {
              name = "very-blank";
              email = "aapeli.saarelainen.76@gmail.com";
            };
          };
        };
      };
    };
}
