{
  self,
  pkgs,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    ron-schema = pkgs.rustPlatform.buildRustPackage rec {
      pname = "ron-schema-cli";
      version = "1.0.0";

      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-p4tx9REKlvo0mgKGOvzh1RUKAVHxWk21HgyDAjdldd4=";
      };

      cargoHash = "sha256-beKONgUIDLi83mRQxVEv41vhSNWQsNXsMt6P6I79I6A=";

      meta.mainProgram = "ron-schema";
    };
  in {
    packages.anyrun = lib.makeOverridable ({
      x ? 0.5,
      y ? 0.35,
      width ? 800,
      height ? 1,
      hideIcons ? true,
      ignoreExclusiveZones ? false,
      hidePluginInfo ? true,
      closeOnClick ? true,
      showResultsImmediately ? false,
      font ? {
        package = pkgs.nerd-fonts._0xproto;
        family = "0xProto Nerd Font";
      },
      keybinds ? [
        {
          key = "Return";
          action = "Select";
        }
        {
          key = "y";
          action = "Select";
          modifiers = ["ctrl"];
        }
        {
          key = "Escape";
          action = "Close";
        }
        {
          key = "p";
          action = "Up";
          modifiers = ["ctrl"];
        }
        {
          key = "n";
          action = "Down";
          modifiers = ["ctrl"];
        }
      ],
    }: let
      validate = schema: file:
        pkgs.runCommand "validated-${file.name}"
        {nativeBuildInputs = [ron-schema];}
        ''
          ron-schema validate --schema ${schema} ${file}
          cp ${file} $out
        '';

      schema = pkgs.writeText "anyrun.ronschema" ''
        (
          x: Dimension,
          y: Dimension,
          width: Dimension,
          height: Dimension,
          hide_icons: Bool,
          ignore_exclusive_zones: Bool,
          layer: Layer,
          hide_plugin_info: Bool,
          close_on_click: Bool,
          show_results_immediately: Bool,
          max_entries: Option(Integer),
          plugins: [String],
          keybinds: [Keybind],
        )

        enum Dimension { Absolute(Integer), Fraction(Float) }
        enum Layer { Background, Bottom, Top, Overlay }
        enum Action { Close, Select, Up, Down }

        type Keybind = (
          key: String,
          action: Action,
          ctrl: Bool = false,
          alt: Bool = false,
          shift: Bool = false,
        )
      '';

      numToString = num:
        if (builtins.isInt num)
        then "Absolute(${lib.toString num})"
        else "Fraction(${lib.toString (lib.max 0.0 (lib.min 1.0 num))})";

      keyToString = {
        key,
        modifiers ? [],
        action,
      }: ''(key: "${key}", action: ${action}, ${lib.strings.concatStringsSep ", " (map (modifier: "${modifier}: ${lib.boolToString (builtins.elem modifier modifiers)}") ["shift" "ctrl" "alt"])})'';

      config = pkgs.writeText "config.ron" ''
        (
          x: ${numToString x},
          y: ${numToString y},
          width: ${numToString width},
          height: ${numToString height},
          hide_icons: ${lib.boolToString hideIcons},
          ignore_exclusive_zones: ${lib.boolToString ignoreExclusiveZones},
          layer: Overlay,
          hide_plugin_info: ${lib.boolToString hidePluginInfo},
          close_on_click: ${lib.boolToString closeOnClick},
          show_results_immediately: ${lib.boolToString showResultsImmediately},
          max_entries: None,
          plugins: [
            "${pkgs.anyrun}/lib/libapplications.so",
            "${pkgs.anyrun}/lib/libshell.so",
            "${pkgs.anyrun}/lib/libtranslate.so",
          ],
          keybinds: [
            ${lib.strings.concatStringsSep ",\n" (map keyToString keybinds)}
          ],
        )
      '';

      style = pkgs.writeText "style.css" (self.css.anyrun {
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
        fontFamily = font.family;
      });

      configDir = pkgs.linkFarm "anyrun-config" [
        {
          name = "config.ron";
          path = validate schema config;
        }
        {
          name = "style.css";
          path = style;
        }
      ];

      fontConfig = self.lib.mkFontsConf pkgs font.package;
    in (pkgs.symlinkJoin {
      name = "anyrun";
      paths = [pkgs.anyrun];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--config-dir=${configDir}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/anyrun"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
          "--set FONTCONFIG_FILE ${fontConfig}"
        ];
    })) {};
  };

  flake = {
    css.anyrun = {
      palette,
      fontFamily,
    }: ''
      @define-color accent ${palette.base0D};
      @define-color bg-color ${palette.base00};
      @define-color fg-color ${palette.base0B};
      @define-color desc-color ${palette.base03};

      window {
        background: transparent;
      }

      box.main {
        padding: 5px;
        margin: 10px;
        border-radius: 5px;
        border: 2px solid @accent;
        background-color: @bg-color;
        box-shadow: 0 0 5px black;
      }

      text {
        font-family: '${fontFamily}';
        min-height: 30px;
        padding: 5px;
        border-radius: 5px;
        color: @fg-color;
      }

      .matches {
        background-color: rgba(0, 0, 0, 0);
        border-radius: 10px;
      }

      box.plugin:first-child {
        margin-top: 5px;
      }

      box.plugin.info {
        min-width: 200px;
      }

      list.plugin {
        background-color: rgba(0, 0, 0, 0);
      }

      label.match {
        color: @fg-color;
      }

      label.match.description {
        font-size: 12px;
        font-weight: bold;
        font-family: '${fontFamily}';
        color: @desc-color;
      }

      label.plugin.info {
        font-size: 14px;
        font-family: '${fontFamily}';
        color: @fg-color;
      }

      .match {
        background: transparent;
      }

      .match:selected {
        border-left: 2px solid @accent;
        background: transparent;
        animation: fade 0.1s linear;
      }

      @keyframes fade {
        0% {
          opacity: 0;
        }

        100% {
          opacity: 1;
        }
      }
    '';
  };
}
