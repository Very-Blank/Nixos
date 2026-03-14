{
  lib,
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

      services.borgbackup.jobs."vaultwarden" = lib.mkIf config.modules.server.borg.enable {
        repo = "user@machine:/path/to/repo";
        encryption = {
          mode = "filekey-blake2";
          passCommand = "cat /path/to/passphrase_file";
        };

        privateTmp = true;

        preHook = ''
          mkdir /tmp/vaultwarden/
          sqlite3 /var/lib/vaultwarden/db.sqlite3 "VACUUM INTO '/tmp/vaultwarden/db.sqlite3'"
          cp -r /var/lib/vaultwarden/attachments /tmp/vaultwarden/attachments/
        '';

        paths = ["/tmp/./vaultwarden/"];

        postHook = ''
          rm -r /tmp/vaultwarden/
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
