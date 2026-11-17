{
  flake = {
    nixosModules.vaultwarden = {config, ...}: {
      sops = {
        secrets = {
          "vaultwarden/env" = {
            sopsFile = ../../../secrets/services/vaultwarden.yaml;
          };
        };
      };

      services = {
        vaultwarden = {
          enable = true;
          environmentFile = config.sops.secrets."vaultwarden/env".path;

          config = {
            DOMAIN = "https://vault.${config.core.host.domain}";
            SIGNUPS_ALLOWED = false;

            ROCKET_ADDRESS = "127.0.0.1";
            ROCKET_PORT = 8222;
            ROCKET_LOG = "critical";
          };
        };
      };
    };

    nixosModules.vaultwardenPersistent = {
      preservation = {
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/var/lib/vaultwarden";
              user = "vaultwarden";
              group = "vaultwarden";
              mode = "0700";
            }
          ];
        };
      };
    };

    nixosModules.vaultwardenNginx = {
      lib,
      config,
      ...
    }: {
      services = {
        nginx = {
          virtualHosts = {
            "vault.${config.core.host.domain}" = {
              useACMEHost = config.core.host.domain;
              forceSSL = true;

              locations."/" = {
                proxyPass = "http://127.0.0.1:${lib.toString config.services.vaultwarden.config.ROCKET_PORT}";
                proxyWebsockets = true;
              };
            };
          };
        };
      };
    };

    nixosModules.vaultwardenBorg = {
      pkgs,
      config,
      ...
    }: let
      borg = config.features.borg;
    in {
      services = {
        borgbackup = {
          jobs = {
            vaultwarden = {
              repo = borg.repo "vaultwarden-backup";
              archiveBaseName = "vaultwarden-archive";

              doInit = true;
              startAt = "*-*-* 3:00:00";

              encryption = {
                inherit (borg.encryption) mode passCommand;
              };

              environment = borg.environment;

              prune.keep = borg.prune;

              privateTmp = true;

              # NOTE: The job runs with ProtectSystem=strict, but sqlite needs to be able to write the
              #       -shm file to read a WAL-mode database.
              readWritePaths = ["/var/lib/vaultwarden"];

              preHook = ''
                mkdir /tmp/vaultwarden/
                ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 "VACUUM INTO '/tmp/vaultwarden/db.sqlite3'"
                if [ -d /var/lib/vaultwarden/attachments ]; then
                  cp -r /var/lib/vaultwarden/attachments /tmp/vaultwarden/attachments
                fi

                chown -R vaultwarden:vaultwarden /tmp/vaultwarden
              '';

              # https://borgbackup.readthedocs.io/en/stable/usage/create.html
              # Backup /tmp/vaultwarden/, but strip path prefix using the slashdot hack.
              paths = ["/tmp/./vaultwarden/"];

              postHook = ''
                rm -r /tmp/vaultwarden
              '';
            };
          };
        };
      };

      features = {
        borg = {
          restores = {
            vaultwarden = {
              prepare = ''
                if systemctl is-active --quiet vaultwarden.service; then
                  echo "Stopping vaultwarden service."
                  systemctl stop vaultwarden.service
                fi
              '';

              restore = ''
                rm -f /var/lib/vaultwarden/db.sqlite3*
                rm -rf /var/lib/vaultwarden/attachments

                cd /var/lib/
                "$WRAPPER" extract ::"$ARCHIVE"
              '';

              finish = ''
                echo "Starting vaultwarden service."
                systemctl start vaultwarden.service
              '';
            };
          };
        };
      };
    };
  };
}
