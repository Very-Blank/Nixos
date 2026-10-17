{
  flake = {
    nixosModules.host = {lib, ...}: {
      options = {
        core = {
          host = {
            name = lib.mkOption {
              default = "nixos";
              description = "The systems/hosts name.";
              type = lib.types.nonEmptyStr;
            };

            type = lib.mkOption {
              type = lib.types.enum [
                "live"
                "vm"
              ];
              description = "Is the system a VM or not.";
              default = "live";
            };

            features = lib.mkOption {
              type = lib.types.listOf (lib.types.enum [
                "battery"
                "bluetooth"
                "wifi"
              ]);
              description = "What features does the host have.";
              default = [];
            };

            outputs = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    mode = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          width = lib.mkOption {
                            type = lib.types.int;
                            description = "Display width in pixels";
                          };
                          height = lib.mkOption {
                            type = lib.types.int;
                            description = "Display height in pixels";
                          };
                          refresh = lib.mkOption {
                            type = lib.types.float;
                            description = "Refresh rate in Hz";
                          };
                        };
                      };
                      description = "Display mode configuration";
                    };

                    scale = lib.mkOption {
                      type = lib.types.float;
                      default = 1.0;
                    };

                    position = lib.mkOption {
                      type = lib.types.submodule {
                        options = {
                          x = lib.mkOption {
                            type = lib.types.int;
                            description = "Display position in pixels";
                            default = 0;
                          };
                          y = lib.mkOption {
                            type = lib.types.int;
                            description = "Display position in pixels";
                            default = 0;
                          };
                        };
                      };
                      description = "Display position configuration";
                    };

                    main = lib.mkEnableOption "Main output.";
                  };
                }
              );

              default = {};
              description = "Monitor output configurations";
              example = {
                "PNP(AOC) 2590G5 0x00002709" = {
                  mode = {
                    width = 1920;
                    height = 1080;
                    refresh = 74.973;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
