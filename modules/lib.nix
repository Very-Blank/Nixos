{
  lib,
  self,
  inputs,
  ...
}: {
  flake = {
    lib = {
      mkNixosSystem = {modules ? []}:
        inputs.nixpkgs.lib.nixosSystem {
          modules =
            [
              self.nixosModules.sops
              self.nixosModules.disko
              self.nixosModules.perservation
              self.nixosModules.host
              self.nixosModules.unfree
              inputs.hjem.nixosModules.default
              ({...}: {
                security.sudo.extraConfig = ''
                  Defaults lecture="never"
                '';
              })
            ]
            ++ modules;
        };

      evalConfig = pkgs: options: module: (lib.evalModules {
        modules = [
          {
            config = {
              _module.args = {
                pkgs = pkgs;
              };
            };
          }
          options
          module
        ];
      });

      mkUnitFile = pkgs: name: module: let
        attrs = self.lib.evalConfig pkgs self.configOptions.units module;

        sectionToValue = attrs: name: let
          values =
            lib.mapAttrsToList
            (
              name: value:
                if builtins.isList value
                then
                  (lib.concatStringsSep
                    "\n") (map (v: "${name}=${v}") value)
                else "${name}=${value}"
            )
            (lib.filterAttrs
              (_: value: (value != null) && value != [])
              attrs.config.${name});
        in
          if values != []
          then [
            (lib.concatStringsSep
              "\n"
              (
                [
                  "[${name}]"
                ]
                ++ values
              ))
          ]
          else [];
      in (pkgs.writeText name
        (lib.concatStringsSep "\n\n"
          (
            lib.concatLists
            [
              (sectionToValue attrs "Unit")
              (sectionToValue attrs "Service")
            ]
          )));
    };

    configOptions.units = {lib, ...}: let
      mkStrOption = description:
        lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = description;
          default = null;
        };

      mkNullOrStrOption = description:
        lib.mkOption {
          type = lib.types.nullOr lib.types.nonEmptyStr;
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
      options = {
        Unit = {
          Description = mkStrOption ''
            A brief, meaningful, human-readable text identifying the unit.

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Description=)
          '';

          Documentation = mkNullOrStrOption ''
            URI of the type "http://", "https://", "file:", "info:" or "man:".

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Documentation=)
          '';

          PartOf = mkListOfStrOption ''
            Configures dependencies similar to Requires=,
            but limited to stopping and restarting of units.
            When systemd stops or restarts the units listed here,
            the action is propagated to this unit.

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#PartOf=)
          '';

          Before = mkListOfStrOption ''
            Configures ordering dependencies between units.
            If unit foo.service contains the setting Before=bar.service and both units are being started,
            bar.service's start-up is delayed until foo.service has finished starting up.a

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Before=)
          '';

          After = mkListOfStrOption ''
            Configures ordering dependencies between units.
            If unit foo.service contains the setting After=bar.service and both units are being started,
            foo.service's start-up is delayed until bar.service has finished starting up.

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Before=)
          '';
        };

        Service = {
          Type = lib.mkOption {
            type = lib.types.enum [
              "simple"
              "exec"
              "forking"
              "oneshot"
              "dbus"
              "notify"
              "notify-reload"
              "idle"
            ];

            description = ''
              Configures the mechanism via which the service notifies the manager that the service start-up has finished.
              [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#Type=)
            '';
          };

          ExecStart = mkListOfStrOption ''
            Commands that are executed when this service is started.

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#ExecStart=)
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

              [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#Restart=)
            '';
          };

          RestartSec = mkNullOrStrOption ''
            Configures the time to sleep before restarting a service (as configured with Restart=).
            Takes a unit-less value in seconds, or a time span value such as "5min 20s". Defaults to 100ms.

            [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#RestartSec=)
          '';

          KillMode = lib.mkOption {
            type = lib.types.enum [
              "control-group"
              "mixed"
              "process"
              "none"
            ];

            description = ''
              Specifies how processes of this unit shall be killed.
              [Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html#KillMode=)
            '';
          };
        };
      };
    };
  };
}
