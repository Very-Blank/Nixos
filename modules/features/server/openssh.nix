{
  flake = {
    nixosModules.openssh = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        modules = {
          openssh = {
            port = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 22;
              description = ''
                Port that the ssh service uses.
              '';
            };

            users = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  authorizedKeys = lib.mkOption {
                    type = lib.types.listOf lib.types.singleLineStr;
                    description = ''
                      The authorized keys that can ssh to this user.
                    '';
                    default = [];
                  };
                };
              });

              default = {};
            };

            banner = lib.mkOption {
              type = lib.types.nullOr lib.types.nonEmptyStr;
              description = ''
                Banner to display on ssh.
              '';
              default = null;
            };
          };
        };
      };

      config = let
        cfg = config.modules.server.openssh;
      in {
        services = {
          openssh = {
            enable = true;
            ports = [cfg.port];
            openFirewall = false;

            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;

              Macs = lib.mkForce ["hmac-sha2-512-etm@openssh.com"];
              Ciphers = lib.mkForce ["chacha20-poly1305@openssh.com"];
              KexAlgorithms = lib.mkForce ["mlkem768x25519-sha256"];

              AllowUsers =
                lib.attrNames
                cfg.users;

              Banner =
                lib.mkIf
                (cfg.banner != null)
                "${pkgs.writeText "Banner" cfg.banner}";
            };
          };

          fail2ban = {
            enable = true;
            maxretry = 2;

            bantime = "2h";
            bantime-increment = {
              enable = true;
              multipliers = "1 2 4 8 16 32 64";
              rndtime = "2h";
            };

            jails = {
              sshd = {
                settings = {
                  enable = true;
                  backend = "systemd";
                  mode = "aggressive";
                  bantime = "2h";
                  maxretry = 2;
                };
              };
            };
          };
        };

        users.users =
          lib.mapAttrs
          (name: value: {openssh.authorizedKeys.keys = value.authorizedKeys;})
          cfg.users;

        networking.firewall.allowedTCPPorts = [cfg.port];
      };
    };
  };
}
