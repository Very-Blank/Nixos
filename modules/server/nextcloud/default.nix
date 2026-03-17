{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        nextcloud = {
          enable = lib.mkEnableOption "Enables the nextcloud module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.nextcloud;
    subdomainName = "cloud";
  in
    lib.mkIf cfg.enable {
      sops.secrets."nextcloud/adminpass".sopsFile = ../../../secrets/other/. + "/${config.hostname}.yaml";

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud33;
        hostName = "${subdomainName}.${config.modules.server.domain.main}";

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
          adminuser = config.hostname;
          adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
          dbtype = "pgsql";
        };
      };

      environment.systemPackages = let
        safetyCheck = ''
          if [[ $EUID -ne 0 ]]; then
            echo "Restore must be run as root." >&2
            exit 1
          fi

          if [[ $(systemctl is-active --quiet nextcloud.service) -eq 0 ]]; then
            echo "Nextcloud service is active!"
            echo "Putting nextcloud service into maintenance mode."

            ${lib.getExe config.services.nextcloud.occ} maintenance:mode --on
          fi
        '';

        # https://search.nixos.org/options?channel=unstable&query=borgbackup&show=services.borgbackup.jobs.%3Cname%3E.wrapper
        wrapper = config.services.borgbackup.jobs."nextcloud".wrapper;

        baseSetup = x: let
          base = "${lib.getExe' pkgs.postgresql "psql"} -d nextcloud";

          databaseCommand = sql: "${base} -c ${sql}";

          dropDatabaseCommand = databaseCommand "DROP DATABASE \"nextcloud\";";
          createDatabaseCommand = databaseCommand "CREATE DATABASE \"nextcloud\";";

          copyData = "${base} -d nextcloud -f /var/lib/nextcloud/nextcloud-database.bak";
        in ''
          rm -rf /var/lib/nextcloud/data
          rm -rf /var/lib/nextcloud/store-apps

          find /var/lib/nextcloud/config/ \! -type l -delete

          cd /var/lib/
          ${wrapper} extract ::"${x}"

          ${lib.getExe' pkgs.util-linux "runuser"} -l postgres -c '${dropDatabaseCommand} ; ${createDatabaseCommand} ; ${copyData}'

          rm -rf /var/lib/nextcloud/nextcloud-database.bak
        '';

        # A script wrapper to a wrapper lol
        # FIXME:  Should prob remove runtimeInputs!
        restoreNextcloudScript = pkgs.writeShellApplication {
          name = "nextcloud-restore";
          runtimeInputs = [pkgs.borgbackup];
          text =
            ''
              if [[ "$#" -ne 1 ]]; then
                echo "Illegal number of parameters."
                echo "Usage: vaultwarden-restore ARCHIVE"
                exit 1
              fi
            ''
            + safetyCheck
            + (baseSetup "$1");
        };

        restoreLatestVaultScript = pkgs.writeShellApplication {
          name = "nextcloud-restore-latest";
          runtimeInputs = [pkgs.borgbackup];
          text =
            safetyCheck
            + ''
              ARCHIVE="$(${wrapper} list --last 1 --short)"
            ''
            + (baseSetup "$ARCHIVE");
        };
      in
        lib.mkIf config.modules.server.borg.enable [restoreNextcloudScript restoreLatestVaultScript];

      # https://docs.nextcloud.com/server/stable/admin_manual/maintenance/backup.html
      services.borgbackup.jobs."nextcloud" = lib.mkIf config.modules.server.borg.enable {
        repo = config.modules.server.borg.repo "nextcloud-backup";
        archiveBaseName = "nextcloud-archive";

        doInit = true;
        startAt = "*-*-* 3:00:00";

        encryption = {
          mode = config.modules.server.borg.encryption.mode;
          passCommand = config.modules.server.borg.encryption.passCommand;
        };

        environment = config.modules.server.borg.environment;

        privateTmp = true;

        # https://search.nixos.org/options?channel=unstable&query=borgbackup&show=services.borgbackup.jobs.%3Cname%3E.readWritePaths
        # NOTE: Truning on maintance mode is done by writing to config.php and other things!!!!
        readWritePaths = ["/var/lib/nextcloud/"];

        # Because borg doesn't seem to have an option to ignore symlinks,
        # we filter them ourself.
        preHook = ''
          ${lib.getExe config.services.nextcloud.occ} maintenance:mode --on

          mkdir /tmp/nextcloud
          cp -rf /var/lib/nextcloud/config /tmp/nextcloud/
          find /tmp/nextcloud/config/ -type l -delete

          ${lib.getExe' pkgs.util-linux "runuser"} -l postgres -c '${lib.getExe' pkgs.postgresql "pg_dump"} -d nextcloud' > /tmp/nextcloud/nextcloud-database.bak

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
          ${lib.getExe config.services.nextcloud.occ} maintenance:mode --off

          rm -r /tmp/nextcloud
        '';
      };

      services.fail2ban = {
        enable = true;
        # The jail file defines how to handle the failed authentication attempts found by the Nextcloud filter
        # Ref: https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html#setup-a-filter-and-a-jail-for-nextcloud
        jails = {
          nextcloud.settings = {
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

      environment.etc = {
        # Adapted failregex for syslogs
        "fail2ban/filter.d/nextcloud.local".text = pkgs.lib.mkDefault (pkgs.lib.mkAfter ''
          [Definition]
          failregex = ^.*"remoteAddr":"<HOST>".*"message":"Login failed:
                      ^.*"remoteAddr":"<HOST>".*"message":"Two-factor challenge failed:
                      ^.*"remoteAddr":"<HOST>".*"message":"Trusted domain error.
        '');
      };

      services.nginx.virtualHosts.${"${subdomainName}.${config.modules.server.domain.main}"} = lib.mkIf config.modules.server.nginx.enable {
        useACMEHost = config.modules.server.domain.main;
        forceSSL = true;
      };
    };
}
