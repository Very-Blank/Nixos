{
  self,
  inputs,
  ...
}: {
  flake = {
    homeModules.vicinae = {
      programs.vicinae = {
        enable = true;

        settings = {
          theme = {
            name = "theme";
          };
        };

        themes = {
          theme = {
            meta = {
              name = "theme";
              variant = "dark";
              description = "My base16 theme.";
            };

            colors = let
              palette = inputs.colors.lib.withHash self.globals.theme.palette;
            in {
              core = {
                background = "${palette.base00}";
                foreground = "${palette.base05}";
                secondary_background = "${palette.base01}";
                border = "${palette.base02}";
                accent = "${palette.base0D}";
              };

              accents = {
                blue = "${palette.base0D}";
                green = "${palette.base0B}";
                magenta = "${palette.base0E}";
                orange = "${palette.base09}";
                purple = "${palette.base0E}";
                red = "${palette.base08}";
                yellow = "${palette.base0A}";
                cyan = "${palette.base0C}";
              };

              list.item = {
                selection = {
                  background.name = "${palette.base02}";
                  secondary_background = "${palette.base03}";
                };

                hover.background = "${palette.base01}";
              };
            };
          };
        };
      };
    };
  };
}
