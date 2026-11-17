{
  flake = {
    nixosModules.nextcloud = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        features = {
          nextcloud = {
            admin = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "admin";
              description = ''
                Name of the admin user, created automatically on boot if it doesn't exist.
                The password is read from the `nextcloud/adminpass` secret.
              '';
            };
          };
        };
      };

      config = {
        sops = {
          secrets = {
            "nextcloud/adminpass" = {
              sopsFile = ../../../secrets/services/nextcloud.yaml;
            };
          };
        };

        systemd = {
          services = {
            # Since nixpkgs no longer creates the admin user, create it once here.
            nextcloud-create-admin = {
              description = "Create the nextcloud admin user";
              wantedBy = ["multi-user.target"];
              requires = ["nextcloud-setup.service"];
              after = ["nextcloud-setup.service"];

              serviceConfig = {
                Type = "oneshot";
                User = "nextcloud";
                # NOTE: occ inherits CREDENTIALS_DIRECTORY when it's set, so the
                #       nextcloud credentials have to be loaded here too, like nixpkgs does
                #       for its own nextcloud units.
                LoadCredential =
                  config.systemd.services.nextcloud-setup.serviceConfig.LoadCredential
                  ++ ["adminpass:${config.sops.secrets."nextcloud/adminpass".path}"];
              };

              script = let
                occ = lib.getExe config.services.nextcloud.occ;
                admin = lib.strings.escapeShellArg config.features.nextcloud.admin;
              in ''
                if ${occ} user:info ${admin} > /dev/null 2>&1; then
                  exit 0
                fi

                if [ -z "$(< "$CREDENTIALS_DIRECTORY/adminpass")" ]; then
                  echo "nextcloud/adminpass secret is empty!" >&2
                  exit 1
                fi

                OC_PASS="$(< "$CREDENTIALS_DIRECTORY/adminpass")"
                export OC_PASS

                ${occ} user:add --password-from-env --group admin ${admin}
              '';
            };
          };
        };

        services = {
          nextcloud = {
            enable = true;
            package = pkgs.nextcloud35;
            hostName = "cloud.${config.core.host.domain}";

            extraApps = {
              inherit (config.services.nextcloud.package.packages.apps) calendar tasks bookmarks;
            };

            https = true;
            extraAppsEnable = true;
            configureRedis = true;
            maxUploadSize = "1G";
            database.createLocally = true;

            # A value of 2, e.g.,
            # will only run these background jobs between 02:00am UTC and 06:00am UTC.
            settings = {
              maintenance_window_start = 2;
            };

            phpOptions = {
              "opcache.interned_strings_buffer" = "16";
            };

            config = {
              dbtype = "pgsql";
            };
          };

          fail2ban = {
            enable = true;
            # The jail file defines how to handle the failed authentication attempts found by the Nextcloud filter
            # Ref: https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html#setup-a-filter-and-a-jail-for-nextcloud
            jails = {
              nextcloud = {
                settings = {
                  # START modification to work with syslog instead of logile
                  backend = "systemd";
                  journalmatch = "SYSLOG_IDENTIFIER=Nextcloud";
                  # END modification to work with syslog instead of logile
                  enabled = true;
                  port = 443;
                  protocol = "tcp";
                  filter = "nextcloud";
                  maxretry = 3;
                  bantime = 86400;
                  findtime = 43200;
                };
              };
            };
          };
        };

        environment = {
          etc = {
            # Adapted failregex for syslogs
            "fail2ban/filter.d/nextcloud.local".text = lib.mkDefault (lib.mkAfter ''
              [Definition]
              failregex = ^.*"remoteAddr":"<HOST>".*"message":"Login failed:
                          ^.*"remoteAddr":"<HOST>".*"message":"Two-factor challenge failed:
                          ^.*"remoteAddr":"<HOST>".*"message":"Trusted domain error.
            '');
          };
        };
      };
    };

    nixosModules.nextcloudPersistent = {
      preservation = {
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/var/lib/nextcloud";
              user = "nextcloud";
              group = "nextcloud";
              mode = "0750";
            }
            {
              directory = "/var/lib/postgresql";
              user = "postgres";
              group = "postgres";
              mode = "0750";
            }
          ];
        };
      };
    };

    nixosModules.nextcloudNginx = {config, ...}: {
      services = {
        nginx = {
          virtualHosts = {
            ${config.services.nextcloud.hostName} = {
              useACMEHost = config.core.host.domain;
              forceSSL = true;
            };
          };
        };
      };
    };

    # https://docs.nextcloud.com/server/stable/admin_manual/maintenance/backup.html
    nixosModules.nextcloudBorg = {
      lib,
      pkgs,
      config,
      ...
    }: let
      borg = config.features.borg;
      occ = lib.getExe config.services.nextcloud.occ;
      runuser = lib.getExe' pkgs.util-linux "runuser";
      psql = lib.getExe' config.services.postgresql.package "psql";
    in {
      services = {
        borgbackup = {
          jobs = {
            nextcloud = {
              repo = borg.repo "nextcloud-backup";
              archiveBaseName = "nextcloud-archive";

              doInit = true;
              startAt = "*-*-* 3:00:00";

              encryption = {
                inherit (borg.encryption) mode passCommand;
              };

              environment = borg.environment;

              prune.keep = borg.prune;

              privateTmp = true;

              # https://search.nixos.org/options?channel=unstable&query=borgbackup&show=services.borgbackup.jobs.%3Cname%3E.readWritePaths
              # NOTE: Turning on maintenance mode is done by writing to config.php and other things!
              readWritePaths = ["/var/lib/nextcloud/"];

              # Because borg doesn't seem to have an option to ignore symlinks,
              # we filter them ourself.
              preHook = ''
                ${occ} maintenance:mode --on

                mkdir /tmp/nextcloud
                cp -rf /var/lib/nextcloud/config /tmp/nextcloud/
                find /tmp/nextcloud/config/ -type l -delete

                ${runuser} -l postgres -c '${lib.getExe' config.services.postgresql.package "pg_dump"} -d nextcloud' > /tmp/nextcloud/nextcloud-database.bak

                chown -R nextcloud:nextcloud /tmp/nextcloud
              '';

              # NOTE: Missing: "/var/lib/./nextcloud/themes/"
              # As I don't have it, and it's creating "failed" archives when it's missing.
              paths = [
                "/tmp/./nextcloud/"
                "/var/lib/./nextcloud/data/"
                "/var/lib/./nextcloud/store-apps/"
              ];

              postHook = ''
                ${occ} maintenance:mode --off

                rm -r /tmp/nextcloud
              '';
            };
          };
        };
      };

      features = {
        borg = {
          restores = {
            nextcloud = {
              # NOTE: Everything that might hold a database connection has to be stopped,
              #       otherwise postgres refuses to drop the database.
              prepare = ''
                echo "Stopping nextcloud services."
                systemctl stop nextcloud-cron.timer nextcloud-cron.service phpfpm-nextcloud.service
              '';

              restore = let
                databaseCommand = sql: "${psql} -d template1 -c \"${sql}\"";
              in ''
                rm -rf /var/lib/nextcloud/data
                rm -rf /var/lib/nextcloud/store-apps

                find /var/lib/nextcloud/config/ \! -type l -and \! -type d -delete

                cd /var/lib/
                "$WRAPPER" extract ::"$ARCHIVE"

                ${runuser} -l postgres -c '${databaseCommand "DROP DATABASE IF EXISTS \\\"nextcloud\\\";"} && ${databaseCommand "CREATE DATABASE \\\"nextcloud\\\" OWNER \\\"nextcloud\\\";"} && ${psql} -v ON_ERROR_STOP=1 -d nextcloud -f /var/lib/nextcloud/nextcloud-database.bak' > /dev/null

                rm -rf /var/lib/nextcloud/nextcloud-database.bak
              '';

              # https://docs.nextcloud.com/server/stable/admin_manual/maintenance/restore.html
              # NOTE: The restored config.php is from the backup, which was taken in maintenance mode.
              finish = ''
                echo "Starting nextcloud services."
                systemctl start phpfpm-nextcloud.service

                echo "Taking nextcloud out of maintenance mode."
                ${occ} maintenance:mode --off
                ${occ} maintenance:data-fingerprint

                systemctl start nextcloud-cron.timer
              '';
            };
          };
        };
      };
    };
  };
}
