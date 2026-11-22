{
  flake = {
    nixosModules = {
      vaultwarden = {
        lib,
        config,
        ...
      }: {
        options = {
          features = {
            vaultwarden = {
              domain = lib.mkOption {
                type = lib.types.singleLineStr;
              };
            };
          };
        };

        config = let
          cfg = config.features.vaulwarden;
        in {
          sops = {
            secrets = {
              "users/vaultwarden/env".sopsFile = ../../../secrets/users/vaulwarden.yaml;
            };
          };

          services.vaultwarden = {
            enable = true;
            environmentFile = config.sops.secrets."users/vaultwarden/env".path;

            config = {
              DOMAIN = "https://${cfg.domain}";
              SIGNUPS_ALLOWED = false;

              ROCKET_ADDRESS = "127.0.0.1";
              ROCKET_PORT = 8222;
              ROCKET_LOG = "critical";
            };
          };
        };
      };

      vaulwardenBorgbackup = {
        pkgs,
        config,
        ...
      }: {
        config = {
          assertions = [
            {
              assertion = let wrapper = config.services.borgbackup.jobs."vaultwarden".wrapper; in (wrapper != null || wrapper != "");
              message = ''
                The wrapper is is needed for restore commands,
                it also makes things a lot easier.
              '';
            }
          ];

          environment.systemPackages = let
            safetyCheck = ''
              if [[ $EUID -ne 0 ]]; then
                echo "Restore must be run as root." >&2
                exit 1
              fi

              if [[ $(systemctl is-active --quiet vaultwarden.service) -eq 0 ]]; then
                echo "Vaultwarden service is active!"
                echo "Stopping vaultwarden service."

                systemctl stop vaultwarden.service
              fi
            '';

            # https://search.nixos.org/options?channel=unstable&query=borgbackup&show=services.borgbackup.jobs.%3Cname%3E.wrapper
            wrapper = config.services.borgbackup.jobs."vaultwarden".wrapper;

            baseSetup = x: ''
              rm -f /var/lib/vaultwarden/db.sqlite3*
              rm -rf /var/lib/vaultwarden/attachments
              cd /var/lib/

              ${wrapper} extract ::"${x}"
            '';

            restoreVaultScript = pkgs.writeShellApplication {
              name = "vaultwarden-restore";
              text =
                safetyCheck
                + ''
                  if [[ "$#" -ne 1 ]]; then
                    echo "Illegal number of parameters."
                    echo "Usage: vaultwarden-restore ARCHIVE"
                    exit 1
                  fi
                ''
                + (baseSetup "$1");
            };

            restoreLatestVaultScript = pkgs.writeShellApplication {
              name = "vaultwarden-restore-latest";
              text =
                safetyCheck
                + ''
                  ARCHIVE="$(${wrapper} list --last 1 --short)"
                ''
                + (baseSetup "$ARCHIVE");
            };
          in [
            restoreVaultScript
            restoreLatestVaultScript
          ];

          services = {
            borgbackup = {
              jobs."vaultwarden" = let
                borg = config.features.borg;
              in {
                repo = borg.repo "vaultwarden-backup";
                archiveBaseName = "vaultwarden-archive";

                doInit = true; # This just makes things easier.
                startAt = "*-*-* 3:00:00";

                encryption = {
                  mode = borg.encryption.mode;
                  passCommand = borg.encryption.passCommand;
                };

                environment = borg.environment;

                privateTmp = true;

                preHook = ''
                  mkdir /tmp/vaultwarden/
                  ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 "VACUUM INTO '/tmp/vaultwarden/db.sqlite3'"
                  if [ -d /var/lib/vaultwarden/attachments ]; then
                      cp -r /var/lib/vaultwarden/attachments /tmp/vaultwarden/attachments
                  fi

                  chown -R vaultwarden:vaultwarden /tmp/vaultwarden
                '';

                # https://borgbackup.readthedocs.io/en/stable/usage/create.html
                # Backup /tmp/vaultwarden/, but strip path prefix using the slashdot hack
                paths = ["/tmp/./vaultwarden/"];

                postHook = ''
                  rm -r /tmp/vaultwarden
                '';
              };
            };
          };
        };
      };

      vaulwardenNginx = {config, ...}: {
        services = {
          nginx = {
            virtualHosts.${config.features.vaulwarden.domain} = {
              useACMEHost = config.features.nginx.host;
              forceSSL = true;

              locations."/" = {
                proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
                proxyWebsockets = true;
              };
            };
          };
        };
      };
    };
  };
}
