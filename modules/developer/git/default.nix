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
          settings = {
            init.defaultBranch = "main";

            ignores = [
              "dev.nix"
            ];

            user = {
              name = "very-blank";
              email = "aapeli.saarelainen.76@gmail.com";
            };
          };
        };
      };
    };
}
