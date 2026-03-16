{
  lib,
  pkgs,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        vaultwarden = {
          enable = lib.mkEnableOption "Enables the vaultwarden module.";
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.vaultwarden;
    subdomainName = "vault";
  in
    lib.mkIf cfg.enable {
      sops.secrets."vaultwarden/env".sopsFile = ../../../secrets/other/. + "/${config.hostname}.yaml";

      services.vaultwarden = {
        enable = true;
        environmentFile = config.sops.secrets."vaultwarden/env".path;

        config = {
          DOMAIN = "https://${subdomainName}.${config.modules.server.domain.main}";
          SIGNUPS_ALLOWED = false;

          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";
        };
      };

      environment.systemPackages = let
        baseSetup = x: ''
          rm -f /var/lib/vaultwarden/db.sqlite3*
          rm -rf /var/lib/vaultwarden/attachments
          cd /var/lib/

          borg-job-vaultwarden extract ::"${x}"
        '';

        checkRoot = ''
          if [[ $EUID -ne 0 ]]; then
            echo "Restore must be run as root." >&2
            exit 1
          fi
        '';

        # A script wrapper to a wrapper lol
        restoreVaultScript = pkgs.writeShellApplication {
          name = "vaultwarden-restore";
          runtimeInputs = [pkgs.borgbackup];
          text =
            checkRoot
            + ''
              if [ "$#" -ne 1 ]; then
                echo "Illegal number of parameters."
                echo "Usage: vaultwarden-restore ARCHIVE"
                exit 1
              fi
            ''
            + (baseSetup "$1");
        };

        restoreLatestVaultScript = pkgs.writeShellApplication {
          name = "vaultwarden-restore-latest";
          runtimeInputs = [pkgs.borgbackup];
          text =
            checkRoot
            + ''
              ARCHIVE="$(borg-job-vaultwarden list --last 1 --short)"
            ''
            + (baseSetup "$ARCHIVE");
        };
      in [restoreVaultScript restoreLatestVaultScript];

      services.borgbackup.jobs."vaultwarden" = lib.mkIf config.modules.server.borg.enable {
        repo = config.modules.server.borg.repo "vaultwarden-backup";
        archiveBaseName = "vaultwarden-archive";

        # This just makes things easier.
        doInit = true;

        encryption = {
          mode = config.modules.server.borg.encryption.mode;
          passCommand = config.modules.server.borg.encryption.passCommand;
        };

        environment = config.modules.server.borg.environment;

        privateTmp = true;

        preHook = ''
          mkdir /tmp/vaultwarden/
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 "VACUUM INTO '/tmp/vaultwarden/db.sqlite3'"
          if [ -d /var/lib/vaultwarden/attachments ]; then
              cp -r /var/lib/vaultwarden/attachments /tmp/vaultwarden/attachments
          fi
        '';

        # https://borgbackup.readthedocs.io/en/stable/usage/create.html
        # Backup /tmp/vaultwarden/, but strip path prefix using the slashdot hack
        paths = ["/tmp/./vaultwarden/"];

        postHook = ''
          rm -r /tmp/vaultwarden
        '';
      };

      services.nginx.virtualHosts.${"${subdomainName}.${config.modules.server.domain.main}"} = lib.mkIf config.modules.server.nginx.enable {
        useACMEHost = config.modules.server.domain.main;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
          proxyWebsockets = true;
        };
      };
    };
}
