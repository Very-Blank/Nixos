{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      graphical = {
        theming = {
          gtk = {
            enable = lib.mkEnableOption "Enables the gtk module.";
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.graphical.theming.gtk;
  in
    lib.mkIf cfg.enable {
      programs.dconf.enable = true;

      userHome = {
        gtk = let
          style = import ./style.nix {
            theme = config.colors.palette;
          };
        in {
          enable = true;

          gtk.colorScheme = "dark";

          theme = {
            package = pkgs.adw-gtk3;
            name = "adw-gtk3";
          };

          gtk3.extraCss = style;
          gtk4.extraCss = style;
        };
      };
    };
}
