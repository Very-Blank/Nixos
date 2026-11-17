{
  self,
  inputs,
  lib,
  ...
}: {
  flake = {
    userModules.gtk = user: {
      lib,
      pkgs,
      ...
    }: let
      style = self.css.gtk {
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      settings = {
        gtk-theme-name = "adw-gtk3";
        gtk-icon-theme-name = iconTheme.name;
        gtk-application-prefer-dark-theme = true;
      };

      keyfile = pkgs.writeText "gtk.keyfile" (lib.generators.toDconfINI {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3";
          icon-theme = iconTheme.name;
        };
      });

      dconfDb = pkgs.runCommand "dconf-user-db" {nativeBuildInputs = [pkgs.dconf];} ''
        mkdir keyfiles
        cp ${keyfile} keyfiles/00-gtk
        dconf compile $out keyfiles
      '';

      ini = pkgs.formats.ini {};
    in {
      users.users."${user}" = {
        packages = [
          pkgs.adw-gtk3
          iconTheme.package
          pkgs.adwaita-icon-theme
        ];
      };

      hjem.users.${user} = {
        files = {
          ".config/gtk-3.0/settings.ini".source =
            ini.generate "gtk3-settings.ini" {Settings = settings;};
          ".config/gtk-4.0/settings.ini".source =
            ini.generate "gtk4-settings.ini" {Settings = settings;};

          ".config/gtk-3.0/gtk.css".text = style;
          ".config/gtk-4.0/gtk.css".text = style;

          ".config/dconf/user".source = dconfDb;
        };
      };

      programs.dconf.enable = true;
    };

    css.gtk = {palette}: let
      channel = offset: hex: lib.fromHexString (builtins.substring offset 2 hex) / 255.0;
      rgb = hex: "${toString (channel 1 hex)}, ${toString (channel 3 hex)}, ${toString (channel 5 hex)}";
    in ''
      @define-color accent_color ${palette.base0D};
      @define-color accent_bg_color ${palette.base0D};
      @define-color accent_fg_color ${palette.base00};
      @define-color destructive_color ${palette.base08};
      @define-color destructive_bg_color ${palette.base08};
      @define-color destructive_fg_color ${palette.base00};
      @define-color success_color ${palette.base0B};
      @define-color success_bg_color ${palette.base0B};
      @define-color success_fg_color ${palette.base00};
      @define-color warning_color ${palette.base0E};
      @define-color warning_bg_color ${palette.base0E};
      @define-color warning_fg_color ${palette.base00};
      @define-color error_color ${palette.base08};
      @define-color error_bg_color ${palette.base08};
      @define-color error_fg_color ${palette.base00};
      @define-color window_bg_color ${palette.base00};
      @define-color window_fg_color ${palette.base05};
      @define-color view_bg_color ${palette.base00};
      @define-color view_fg_color ${palette.base05};
      @define-color headerbar_bg_color ${palette.base01};
      @define-color headerbar_fg_color ${palette.base05};
      @define-color headerbar_border_color rgba(${rgb palette.base01}, 0.7);
      @define-color headerbar_backdrop_color @window_bg_color;
      @define-color headerbar_shade_color rgba(0, 0, 0, 0.07);
      @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.07);
      @define-color sidebar_bg_color ${palette.base01};
      @define-color sidebar_fg_color ${palette.base05};
      @define-color sidebar_backdrop_color @window_bg_color;
      @define-color sidebar_shade_color rgba(0, 0, 0, 0.07);
      @define-color secondary_sidebar_bg_color @sidebar_bg_color;
      @define-color secondary_sidebar_fg_color @sidebar_fg_color;
      @define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
      @define-color secondary_sidebar_shade_color @sidebar_shade_color;
      @define-color card_bg_color ${palette.base01};
      @define-color card_fg_color ${palette.base05};
      @define-color card_shade_color rgba(0, 0, 0, 0.07);
      @define-color dialog_bg_color ${palette.base01};
      @define-color dialog_fg_color ${palette.base05};
      @define-color popover_bg_color ${palette.base01};
      @define-color popover_fg_color ${palette.base05};
      @define-color popover_shade_color rgba(0, 0, 0, 0.07);
      @define-color shade_color rgba(0, 0, 0, 0.07);
      @define-color scrollbar_outline_color ${palette.base02};
      @define-color blue_1 ${palette.base0D};
      @define-color blue_2 ${palette.base0D};
      @define-color blue_3 ${palette.base0D};
      @define-color blue_4 ${palette.base0D};
      @define-color blue_5 ${palette.base0D};
      @define-color green_1 ${palette.base0B};
      @define-color green_2 ${palette.base0B};
      @define-color green_3 ${palette.base0B};
      @define-color green_4 ${palette.base0B};
      @define-color green_5 ${palette.base0B};
      @define-color yellow_1 ${palette.base0A};
      @define-color yellow_2 ${palette.base0A};
      @define-color yellow_3 ${palette.base0A};
      @define-color yellow_4 ${palette.base0A};
      @define-color yellow_5 ${palette.base0A};
      @define-color orange_1 ${palette.base09};
      @define-color orange_2 ${palette.base09};
      @define-color orange_3 ${palette.base09};
      @define-color orange_4 ${palette.base09};
      @define-color orange_5 ${palette.base09};
      @define-color red_1 ${palette.base08};
      @define-color red_2 ${palette.base08};
      @define-color red_3 ${palette.base08};
      @define-color red_4 ${palette.base08};
      @define-color red_5 ${palette.base08};
      @define-color purple_1 ${palette.base0E};
      @define-color purple_2 ${palette.base0E};
      @define-color purple_3 ${palette.base0E};
      @define-color purple_4 ${palette.base0E};
      @define-color purple_5 ${palette.base0E};
      @define-color brown_1 ${palette.base0F};
      @define-color brown_2 ${palette.base0F};
      @define-color brown_3 ${palette.base0F};
      @define-color brown_4 ${palette.base0F};
      @define-color brown_5 ${palette.base0F};
      @define-color light_1 ${palette.base05};
      @define-color light_2 ${palette.base05};
      @define-color light_3 ${palette.base05};
      @define-color light_4 ${palette.base05};
      @define-color light_5 ${palette.base05};
      @define-color dark_1 ${palette.base05};
      @define-color dark_2 ${palette.base05};
      @define-color dark_3 ${palette.base05};
      @define-color dark_4 ${palette.base05};
      @define-color dark_5 ${palette.base05};
    '';
  };
}
