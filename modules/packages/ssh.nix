{self, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.ssh = lib.makeOverridable (module: let
      cfg = self.lib.evalConfig pkgs self.configOptions.ssh module;

      configFile =
        pkgs.runCommand "config"
        {
          config = lib.strings.concatStringsSep "\n" (map (host: ''
              Host ${host.match}
                HostName ${host.name}
                IdentityFile ${host.identityFile}
                User ${host.user}
            '')
            cfg.hosts);
          passAsFile = ["config"];
          nativeBuildInputs = [pkgs.openssh];
        }
        ''
          ssh -T -G -F $configPath localhost > /dev/null
          cp $configPath $out
        '';
    in (pkgs.symlinkJoin {
      name = "ssh";
      paths = [pkgs.openssh];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/ssh --add-flags "-F ${configFile}"
      '';

      meta = {
        mainProgram = "ssh";
      };
    })) {};
  };

  flake = {
    configOptions.ssh = {lib, ...}: {
      options = {
        hosts = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                match = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };

                name = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };

                identityFile = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };

                user = lib.mkOption {
                  type = lib.types.nonEmptyStr;
                };
              };
            }
          );

          default = [];
        };
      };
    };
  };
}
