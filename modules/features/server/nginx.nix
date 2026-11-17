{inputs, ...}: {
  flake = {
    nixosModules.nginx = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        features = {
          nginx = {
            acme = {
              email = lib.mkOption {
                type = lib.types.nonEmptyStr;
                description = ''
                  Email address used for ACME registration.
                '';
              };
            };
          };
        };
      };

      config = let
        cfg = config.features.nginx;
        domain = config.core.host.domain;

        # https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
        # https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
        cspOptions = [
          "child-src 'none';"
          "connect-src 'none';"
          "font-src 'none';"
          "img-src 'self';"
          "manifest-src 'none';"
          "media-src 'none';"
          "object-src 'none';"
          "script-src 'none';"
          "script-src-elem 'none';"
          "script-src-attr 'none';"
          "style-src 'self';"
          "style-src-elem 'self';"
          "style-src-attr 'self';"
          "default-src 'self';"
          "base-uri 'none';"
          "form-action 'none';"
          "frame-ancestors 'none';"
        ];

        httpSecurityHeaders = ''
          add_header "Strict-Transport-Security" "max-age=31536000; includeSubDomains; preload" always;

          add_header "X-Frame-Options" "DENY" always;

          add_header "X-Content-Type-Options" "nosniff" always;

          add_header "Content-Security-Policy" "${lib.strings.concatStringsSep " " cspOptions}" always;

          add_header "Cross-Origin-Opener-Policy" "same-origin" always;

          add_header "Cross-Origin-Embedder-Policy" "require-corp" always;

          add_header "Cross-Origin-Resource-Policy" "same-site" always;

          add_header "Permissions-Policy" "geolocation=(), camera=(), microphone=(), interest-cohort=()" always;
        '';
      in {
        sops = {
          secrets = {
            "cloudflare/token" = {
              sopsFile = ../../../secrets/services/cloudflare.yaml;
            };
          };
        };

        security = {
          acme = {
            acceptTerms = true;

            defaults = {
              email = cfg.acme.email;
            };

            certs = {
              ${domain} = {
                group = config.services.nginx.group;
                extraDomainNames = ["*.${domain}"];
                dnsProvider = "cloudflare";
                credentialFiles = {
                  CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare/token".path;
                };
              };
            };
          };
        };

        services = {
          nginx = {
            enable = true;
            serverTokens = false;

            recommendedGzipSettings = true;
            recommendedOptimisation = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;

            appendHttpConfig = ''
              limit_req_zone $binary_remote_addr zone=ip:10m rate=5r/s;
            '';

            virtualHosts = {
              ${domain} = {
                useACMEHost = domain;
                forceSSL = true;

                root = inputs.sefirah.packages.${pkgs.stdenv.hostPlatform.system}.default;

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

              "*.${domain}" = {
                useACMEHost = domain;
                forceSSL = true;
                extraConfig = httpSecurityHeaders;
                globalRedirect = domain;
              };
            };
          };
        };

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [
              80
              443
            ];
          };
        };
      };
    };

    # NOTE: Holds the certificates and the Let's Encrypt account,
    #       losing them means requesting new ones on every boot.
    nixosModules.nginxPersistent = {
      preservation = {
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/var/lib/acme";
              user = "acme";
              group = "acme";
            }
          ];
        };
      };
    };
  };
}
