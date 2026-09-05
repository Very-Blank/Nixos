{self, ...}: {
  flake = {
    homeModules.gtk = {pkgs, ...}: {
      gtk = let
        style = self.css.gtk {
          theme = self.globals.theme.palette;
        };
      in {
        enable = true;

        colorScheme = "dark";

        theme = {
          package = pkgs.adw-gtk3;
          name = "adw-gtk3";
        };

        gtk3.extraCss = style;
        gtk4.extraCss = style;
      };
    };

    css.gtk = {theme}: let
      red = hexColor: builtins.substring 0 2 hexColor;
      green = hexColor: builtins.substring 2 2 hexColor;
      blue = hexColor: builtins.substring 4 2 hexColor;

      hexCharToInt = c:
        if c == "0"
        then 0
        else if c == "1"
        then 1
        else if c == "2"
        then 2
        else if c == "3"
        then 3
        else if c == "4"
        then 4
        else if c == "5"
        then 5
        else if c == "6"
        then 6
        else if c == "7"
        then 7
        else if c == "8"
        then 8
        else if c == "9"
        then 9
        else if c == "a" || c == "A"
        then 10
        else if c == "b" || c == "B"
        then 11
        else if c == "c" || c == "C"
        then 12
        else if c == "d" || c == "D"
        then 13
        else if c == "e" || c == "E"
        then 14
        else if c == "f" || c == "F"
        then 15
        else throw "Invalid hex character: ${c}";

      hexPairToInt = pair: let
        first = builtins.substring 0 1 pair;
        second = builtins.substring 1 1 pair;
      in
        (hexCharToInt first) * 16 + (hexCharToInt second);

      hexColorToFloat = {
        color,
        hex,
      }:
        (hexPairToInt (color hex)) / 255.0;
    in ''
      @define-color accent_color #${theme.base0D};
      @define-color accent_bg_color #${theme.base0D};
      @define-color accent_fg_color #${theme.base00};
      @define-color destructive_color #${theme.base08};
      @define-color destructive_bg_color #${theme.base08};
      @define-color destructive_fg_color #${theme.base00};
      @define-color success_color #${theme.base0B};
      @define-color success_bg_color #${theme.base0B};
      @define-color success_fg_color #${theme.base00};
      @define-color warning_color #${theme.base0E};
      @define-color warning_bg_color #${theme.base0E};
      @define-color warning_fg_color #${theme.base00};
      @define-color error_color #${theme.base08};
      @define-color error_bg_color #${theme.base08};
      @define-color error_fg_color #${theme.base00};
      @define-color window_bg_color #${theme.base00};
      @define-color window_fg_color #${theme.base05};
      @define-color view_bg_color #${theme.base00};
      @define-color view_fg_color #${theme.base05};
      @define-color headerbar_bg_color #${theme.base01};
      @define-color headerbar_fg_color #${theme.base05};
      @define-color headerbar_border_color rgba(${toString (hexColorToFloat {
        color = red;
        hex = theme.base01;
      })}, ${toString (hexColorToFloat {
        color = green;
        hex = theme.base01;
      })}, ${toString (hexColorToFloat {
        color = blue;
        hex = theme.base01;
      })}, 0.7);
      @define-color headerbar_backdrop_color @window_bg_color;
      @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
      @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
      @define-color sidebar_bg_color #${theme.base01};
      @define-color sidebar_fg_color #${theme.base05};
      @define-color sidebar_backdrop_color @window_bg_color;
      @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
      @define-color secondary_sidebar_bg_color @sidebar_bg_color;
      @define-color secondary_sidebar_fg_color @sidebar_fg_color;
      @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
      @define-color secondary_sidebar_shade_color @sidebar_shade_color;
      @define-color card_bg_color #${theme.base01};
      @define-color card_fg_color #${theme.base05};
      @define-color card_shade_color rgba(0, 0, 0, 0.07);
      @define-color dialog_bg_color #${theme.base01};
      @define-color dialog_fg_color #${theme.base05};
      @define-color popover_bg_color #${theme.base01};
      @define-color popover_fg_color #${theme.base05};
      @define-color popover_shade_color rgba(0, 0, 0, 0.07);
      @define-color shade_color rgba(0, 0, 0, 0.07);
      @define-color scrollbar_outline_color #${theme.base02};
      @define-color blue_1 #${theme.base0D};
      @define-color blue_2 #${theme.base0D};
      @define-color blue_3 #${theme.base0D};
      @define-color blue_4 #${theme.base0D};
      @define-color blue_5 #${theme.base0D};
      @define-color green_1 #${theme.base0B};
      @define-color green_2 #${theme.base0B};
      @define-color green_3 #${theme.base0B};
      @define-color green_4 #${theme.base0B};
      @define-color green_5 #${theme.base0B};
      @define-color yellow_1 #${theme.base0A};
      @define-color yellow_2 #${theme.base0A};
      @define-color yellow_3 #${theme.base0A};
      @define-color yellow_4 #${theme.base0A};
      @define-color yellow_5 #${theme.base0A};
      @define-color orange_1 #${theme.base09};
      @define-color orange_2 #${theme.base09};
      @define-color orange_3 #${theme.base09};
      @define-color orange_4 #${theme.base09};
      @define-color orange_5 #${theme.base09};
      @define-color red_1 #${theme.base08};
      @define-color red_2 #${theme.base08};
      @define-color red_3 #${theme.base08};
      @define-color red_4 #${theme.base08};
      @define-color red_5 #${theme.base08};
      @define-color purple_1 #${theme.base0E};
      @define-color purple_2 #${theme.base0E};
      @define-color purple_3 #${theme.base0E};
      @define-color purple_4 #${theme.base0E};
      @define-color purple_5 #${theme.base0E};
      @define-color brown_1 #${theme.base0F};
      @define-color brown_2 #${theme.base0F};
      @define-color brown_3 #${theme.base0F};
      @define-color brown_4 #${theme.base0F};
      @define-color brown_5 #${theme.base0F};
      @define-color light_1 #${theme.base05};
      @define-color light_2 #${theme.base05};
      @define-color light_3 #${theme.base05};
      @define-color light_4 #${theme.base05};
      @define-color light_5 #${theme.base05};
      @define-color dark_1 #${theme.base05};
      @define-color dark_2 #${theme.base05};
      @define-color dark_3 #${theme.base05};
      @define-color dark_4 #${theme.base05};
      @define-color dark_5 #${theme.base05};
    '';
  };
}
