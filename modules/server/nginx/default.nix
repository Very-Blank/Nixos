{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  options = {
    modules = {
      server = {
        nginx = {
          enable = lib.mkEnableOption "Enables the nginx module.";
          acme = {
            email = lib.mkOption {
              description = "Email address.";
              type = lib.types.nonEmptyStr;
            };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.nginx;

    # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
    # https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html

    cspOptions = [
      "child-src 'none';"
      "connect-src 'none';"
      "font-src 'none';"
      "img-src 'self';"
      "manifest-src 'none';"
      "media-src 'none';"
      "prefetch-src 'none';"
      "object-src 'none';"
      "script-src 'none';"
      "script-src-elem 'none';"
      "script-src-attr 'none';"
      "style-src 'self';"
      "style-src-elem 'self';"
      "style-src-attr 'self';"
      "default-src 'self';"
      "base-uri 'none';"
      "plugin-types 'none';"
      "form-action 'none';"
      "frame-ancestors 'none';"
    ];

    # add_header "Strict-Transport-Security" "max-age=31536000" always;
    httpSecurityHeaders = ''
      add_header "X-Frame-Options" "DENY" always;

      add_header "X-Content-Type-Options" "nosniff" always;

      add_header "Content-Security-Policy" "${lib.strings.concatStringsSep " " cspOptions}" always;

      add_header "Cross-Origin-Opener-Policy" "same-origin" always;

      add_header "Cross-Origin-Embedder-Policy" "require-corp" always;

      add_header "Cross-Origin-Resource-Policy" "same-site" always;

      add_header "Permissions-Policy" "geolocation=(), camera=(), microphone=(), interest-cohort=()" always;
    '';
  in
    lib.mkIf cfg.enable {
      sops.secrets."acme/token" = {
        sopsFile = ../../../secrets/other/. + "/${config.hostname}.yaml";
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = cfg.acme.email;

        certs.${config.modules.server.domain.main} = {
          extraDomainNames = ["*.${config.modules.server.domain.main}"];
          dnsProvider = "cloudflare";
          credentialsFile = config.sops.secrets."acme/token".path;
        };
      };

      services.nginx = {
        enable = true;
        serverTokens = false;

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        appendHttpConfig = ''
          limit_req_zone $binary_remote_addr zone=ip:10m rate=5r/s;
          add_header "Strict-Transport-Security" "max-age=31536000; includeSubDomains; preload" always;
        '';

        virtualHosts.${config.modules.server.domain.main} = {
          useACMEHost = config.modules.server.domain.main;
          forceSSL = true;

          root = inputs.sefirah.packages.${pkgs.stdenv.system}.default;

          extraConfig = httpSecurityHeaders;

          locations."/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";

            extraConfig = ''
              limit_req zone=ip burst=12 delay=8;
              limit_req_status 418;
            '';
          };
        };

        virtualHosts."*.${config.modules.server.domain.main}" = {
          forceSSL = true;
          extraConfig = httpSecurityHeaders;
          useACMEHost = config.modules.server.domain.main;
          globalRedirect = config.modules.server.domain.main;
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [
          80
          443
        ];
      };

      users.users."nginx".extraGroups = ["acme"];
    };
}
