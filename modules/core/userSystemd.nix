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
                                type = lib.types.null or lib.types.nonEmptyStr;
                                description = description;
                                default = null;
                              };

                            mkListOfStrOption = description:
                              lib.mkOption {
                                type = lib.types.listOf lib.types.nonEmptyStr;
                                description = description;
                                default = [];
                              };
                          in {
                            Unit = {
                              Description = mkNullOrStrOption ''
                                A brief, meaningful, human-readable text identifying the unit.
                              '';

                              Documentation = mkNullOrStrOption ''
                                URI of the type "http://", "https://", "file:", "info:" or "man:".
                              '';

                              PartOf = mkListOfStrOption ''
                                Configures dependencies similar to Requires=,
                                but limited to stopping and restarting of units.
                                When systemd stops or restarts the units listed here,
                                the action is propagated to this unit.
                              '';

                              Before = mkListOfStrOption ''
                                Configures ordering dependencies between units.
                                If unit foo.service contains the setting Before=bar.service and both units are being started,
                                bar.service's start-up is delayed until foo.service has finished starting up.
                              '';

                              After = mkListOfStrOption ''
                                Configures ordering dependencies between units.
                                If unit foo.service contains the setting After=bar.service and both units are being started,
                                foo.service's start-up is delayed until bar.service has finished starting up.
                              '';
                            };

                            #   Service = {
                            #     Type = "simple";
                            #     ExecStart = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun} daemon";
                            #     Restart = "on-failure";
                            #     RestartSec = "1s";
                            #     KillMode = "process";
                            #   };
                            Service = {
                              ExecStart = mkListOfStrOption ''
                                Commands that are executed when this service is started.
                              '';

                              Restart = lib.mkOption {
                                type = lib.types.enum [
                                  "no"
                                  "on-success"
                                  "on-failure"
                                  "on-abnormal"
                                  "on-watchdog"
                                  "on-abort"
                                  "always"
                                ];

                                default = "no";

                                description = ''
                                  Configures whether the service shall be restarted when the service process exits,
                                  is killed, or a timeout is reached.

                                  Restart settings/Exit causes:
                                    - Clean exit code or signal: [always, on-success]
                                    - Unclean exit:              [always, on-failure]
                                    - Unclean signal:            [always, on-failure, on-abnormal, on-abort]
                                    - Timeout:                   [always, on-failure, on-abnormal]
                                    - Watchdog:                  [always, on-failure, on-abnormal, on-watchdog]
                                    - Termination due to OOM:    [always, on-failure, on-abnormal]
                                '';
                              };
                            };

                            #   Install = {
                            #     WantedBy = ["graphical-session.target"];
                            #   };
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
