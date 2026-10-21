{
  # systemd.user.services.anyrun = {
  #   Unit = {
  #     Description = "Anyrun service";
  #     PartOf = "graphical-session.target";
  #     After = "graphical-session.target";
  #   };
  #
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun} daemon";
  #     Restart = "on-failure";
  #     RestartSec = "1s";
  #     KillMode = "process";
  #   };
  #
  #   Install = {
  #     WantedBy = ["graphical-session.target"];
  #   };
  # };
  flake = {
    nixosModules.userSystemd = {lib, ...}: {
      options = {
        # lib.types.attrsOf
        core = {
          systemd = {
            user = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    service = lib.mkOption {
                      type = lib.types.attrsOf (
                        lib.types.submodule {
                          options = let
                            mkNullOrStrOption = description:
                              lib.mkOption {
                                type = lib.types.nonEmptyStr;
                                description = description;
                                default = null;
                              };

                            mkNullOrListOfStrOption = description:
                              lib.mkOption {
                                type = lib.types.listOf lib.types.nonEmptyStr;
                                description = description;
                                default = [];
                              };
                          in {
                            Unit = lib.types.submodule {
                              options = {
                                Description = mkNullOrStrOption ''
                                  A brief, meaningful, human-readable text identifying the unit.
                                '';

                                Documentation = mkNullOrStrOption ''
                                  URI of the type "http://", "https://", "file:", "info:" or "man:".
                                '';

                                PartOf = mkNullOrListOfStrOption ''
                                  Configures dependencies similar to Requires=,
                                  but limited to stopping and restarting of units.
                                  When systemd stops or restarts the units listed here,
                                  the action is propagated to this unit.
                                '';

                                Before = mkNullOrListOfStrOption ''
                                  Configures ordering dependencies between units.
                                  If unit foo.service contains the setting Before=bar.service and both units are being started,
                                  bar.service's start-up is delayed until foo.service has finished starting up.
                                '';

                                After = mkNullOrListOfStrOption ''
                                  Configures ordering dependencies between units.
                                  If unit foo.service contains the setting Before=bar.service and both units are being started,
                                  bar.service's start-up is delayed until foo.service has finished starting up.
                                '';
                              };
                            };
                          };
                        }
                      );

                      default = {};
                    };
                  };
                }
              );

              default = {};
            };
          };
        };
      };

      config = {
      };
    };
  };
}
