{
  flake = {
    nixosModules.cloudflareDyndns = {config, ...}: {
      sops = {
        secrets = {
          "cloudflare/token" = {
            sopsFile = ../../../secrets/services/cloudflare.yaml;
          };
        };
      };

      services = {
        cloudflare-dyndns = {
          enable = true;
          apiTokenFile = config.sops.secrets."cloudflare/token".path;

          domains = [
            config.core.host.domain
            "*.${config.core.host.domain}"
          ];
        };
      };
    };
  };
}
