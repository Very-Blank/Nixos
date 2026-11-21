{
  self,
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

      meta = {
        mainProgram = "ron-schema";
      };
    };
  in {
    packages.anyrun = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.anyrun module;

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

      keybinds =
        lib.mapAttrsToList
        (key: value: ''(key: "${key}", action: ${value.action}, ${lib.strings.concatStringsSep ", " (map (modifier: "${modifier}: ${lib.boolToString (lib.elem modifier value.modifiers)}") ["shift" "ctrl" "alt"])})'')
        cfg.keybinds;

      config = ''
        (
          x: ${numToString cfg.position.x},
          y: ${numToString cfg.position.y},
          width: ${numToString cfg.size.width},
          height: ${numToString cfg.size.height},
          hide_icons: ${lib.boolToString cfg.hideIcons},
          ignore_exclusive_zones: ${lib.boolToString cfg.ignoreExclusiveZones},
          layer: ${cfg.layer},
          hide_plugin_info: ${lib.boolToString cfg.hidePluginInfo},
          close_on_click: ${lib.boolToString cfg.closeOnClick},
          show_results_immediately: ${lib.boolToString cfg.showResultsImmediately},
          max_entries: ${
          if lib.isString cfg.maxEntries
          then cfg.maxEntries
          else lib.toString cfg.maxEntries
        },
          plugins: [
            "${pkgs.anyrun}/lib/libapplications.so",
            "${pkgs.anyrun}/lib/libshell.so",
            "${pkgs.anyrun}/lib/libtranslate.so",
          ],
          keybinds: [
            ${lib.strings.concatStringsSep ",\n" keybinds}
          ],
        )
      '';

      configFile = pkgs.writeTextFile {
        name = "config.ron";
        text = config;
        checkPhase = ''
          ${lib.getExe ron-schema} validate --schema ${schema} $target
        '';
      };

      style = pkgs.writeText "style.css" (self.css.anyrun {
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
        fontFamily = cfg.font.family;
      });

      configDir = pkgs.linkFarm "anyrun-config" [
        {
          name = "config.ron";
          path = configFile;
        }
        {
          name = "style.css";
          path = style;
        }
      ];

      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [
          cfg.font.package
        ];
      };
    in (pkgs.symlinkJoin {
      name = "anyrun";
      paths = [pkgs.anyrun];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/anyrun \
          --add-flag --config-dir=${configDir} \
          --set FONTCONFIG_FILE ${fontsConf}
      '';

      meta = {
        mainProgram = "anyrun";
      };
    })) {};
  };

  flake = {
    configOptions.anyrun = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = let
        # NOTE: An integer is an absolute size in pixels, a float is a fraction of the screen.
        dimension = lib.types.either lib.types.ints.unsigned (lib.types.numbers.between 0.0 1.0);
      in {
        position = lib.mkOption {
          type = lib.types.submodule {
            options = {
              x = lib.mkOption {
                type = dimension;
              };

              y = lib.mkOption {
                type = dimension;
              };
            };
          };

          default = {
            x = 0.5;
            y = 0.35;
          };
        };

        size = lib.mkOption {
          type = lib.types.submodule {
            options = {
              width = lib.mkOption {
                type = dimension;
              };

              height = lib.mkOption {
                type = dimension;
              };
            };
          };

          default = {
            width = 800;
            height = 1;
          };
        };

        hideIcons =
          lib.mkEnableOption ''
            If icons will be hidden.
          ''
          // {
            default = true;
          };

        ignoreExclusiveZones = lib.mkEnableOption ''
          If exclusive zones should be ignored.
        '';

        hidePluginInfo =
          lib.mkEnableOption ''
            If plugin info is shown.
          ''
          // {
            default = true;
          };

        closeOnClick =
          lib.mkEnableOption ''
            If anyrun closes when clicking outside of it.
          ''
          // {
            default = true;
          };

        showResultsImmediately =
          lib.mkEnableOption ''
            If results should be shown immediately.
          ''
          // {
            default = true;
          };

        layer = lib.mkOption {
          type = lib.types.enum [
            "Background"
            "Bottom"
            "Top"
            "Overlay"
          ];

          default = "Overlay";
        };

        keybinds = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              action = lib.mkOption {
                type = lib.types.enum [
                  "Close"
                  "Select"
                  "Up"
                  "Down"
                ];
              };

              modifiers = lib.mkOption {
                type = lib.types.listOf (lib.types.enum [
                  "ctrl"
                  "alt"
                  "shift"
                ]);

                default = [];
              };
            };
          });

          default = {
            "Return" = {
              action = "Select";
            };

            "y" = {
              action = "Select";
              modifiers = ["ctrl"];
            };

            "Escape" = {
              action = "Close";
            };

            "p" = {
              action = "Up";
              modifiers = ["ctrl"];
            };

            "n" = {
              action = "Down";
              modifiers = ["ctrl"];
            };
          };
        };

        maxEntries = lib.mkOption {
          type = lib.types.either (lib.types.enum ["None"]) lib.types.ints.unsigned;
          default = "None";
        };

        font = lib.mkOption {
          type = lib.types.submodule {
            options = {
              package = lib.mkOption {
                type = lib.types.package;
              };

              family = lib.mkOption {
                type = lib.types.nonEmptyStr;
              };
            };
          };

          default = {
            package = pkgs.nerd-fonts._0xproto;
            family = "0xProto Nerd Font";
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.all (modifiers: lib.allUnique modifiers) (lib.mapAttrsToList (_: value: value.modifiers) config.keybinds);
            message = ''
              Each keybind may list a given modifier at most once.
            '';
          }
        ];
      };
    };

    userModules.anyrunService = user: {
      lib,
      pkgs,
      ...
    }: {
      core.services.${user}.anyrun = {
        Unit = {
          Description = "Anyrun service";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };

        Service = {
          Type = "exec";
          ExecStart = ["${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun} daemon"];
          Restart = "on-failure";
          RestartSec = "1s";
          KillMode = "process";
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    };

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
