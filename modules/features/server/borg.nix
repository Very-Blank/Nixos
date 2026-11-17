{
  flake = {
    nixosModules.borg = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        features = {
          borg = {
            repo = lib.mkOption {
              type = lib.types.functionTo lib.types.nonEmptyStr;
              description = ''
                Function from a job name to the path of its repo.
              '';
              default = name: name;
              example = lib.literalExpression ''name: "/var/repos/''${name}"'';
            };

            encryption = {
              mode = lib.mkOption {
                type = lib.types.enum [
                  "keyfile"
                  "keyfile-blake2"
                ];
                description = ''
                  Encryption mode to use.
                '';
                default = "keyfile";
                example = "keyfile-blake2";
              };

              passCommand = lib.mkOption {
                type = lib.types.nonEmptyStr;
                description = ''
                  A command which prints the passphrase to stdout.
                '';
                default = "cat ${config.sops.secrets."borg/password".path}";
                readOnly = true;
              };
            };

            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = ''
                Environment variables passed to the backup script.
                You can for example specify which SSH key to use.
              '';
              default = {};
              example = {
                BORG_RSH = "ssh -i /path/to/key";
              };
            };

            prune = lib.mkOption {
              type = lib.types.attrsOf (lib.types.either lib.types.int (lib.types.strMatching "[[:digit:]]+[Hdwmy]"));
              description = ''
                Retention options passed to the jobs' `prune.keep`.
              '';
              default = {
                daily = 7;
                weekly = 4;
                monthly = 6;
              };
            };

            restores = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  prepare = lib.mkOption {
                    type = lib.types.lines;
                    description = ''
                      Commands run before restoring, e.g. stopping the service.
                    '';
                    default = "";
                  };

                  restore = lib.mkOption {
                    type = lib.types.lines;
                    description = ''
                      Commands that restore the archive "$ARCHIVE",
                      `$WRAPPER` is the borg job's wrapper.
                    '';
                  };

                  finish = lib.mkOption {
                    type = lib.types.lines;
                    description = ''
                      Commands run after restoring, e.g. starting the service.
                    '';
                    default = "";
                  };
                };
              });
              description = ''
                Restore scripts for borg jobs, creates `<name>-restore` and `<name>-restore-latest`.
              '';
              default = {};
            };
          };
        };
      };

      config = let
        cfg = config.features.borg;

        mkRestoreScripts = name: restore: let
          # https://search.nixos.org/options?channel=unstable&query=borgbackup&show=services.borgbackup.jobs.%3Cname%3E.wrapper
          wrapper = config.services.borgbackup.jobs.${name}.wrapper;

          mkScript = scriptName: getArchive:
            pkgs.writeShellApplication {
              name = scriptName;
              runtimeInputs = [
                pkgs.coreutils
                pkgs.gnugrep
              ];
              text =
                ''
                  if [[ $EUID -ne 0 ]]; then
                    echo "Restore must be run as root." >&2
                    exit 1
                  fi

                  WRAPPER="${wrapper}"
                ''
                + getArchive
                + ''

                  # Make sure the archive exists before anything is deleted.
                  if ! "$WRAPPER" info ::"$ARCHIVE" > /dev/null; then
                    echo "Archive '$ARCHIVE' not found." >&2
                    exit 1
                  fi

                ''
                + restore.prepare
                + restore.restore
                + restore.finish;
            };
        in [
          (mkScript "${name}-restore" ''
            if [[ "$#" -ne 1 ]]; then
              echo "Illegal number of parameters." >&2
              echo "Usage: ${name}-restore ARCHIVE" >&2
              exit 1
            fi

            ARCHIVE="$1"
          '')

          (mkScript "${name}-restore-latest" ''
            # Skip archives from backups that failed midway.
            ARCHIVE="$("$WRAPPER" list --short | { grep -v '\.failed$' || true; } | tail -n 1)"

            if [[ -z "$ARCHIVE" ]]; then
              echo "No complete archive found." >&2
              exit 1
            fi
          '')
        ];
      in {
        sops = {
          secrets = {
            "borg/password" = {
              sopsFile = ../../../secrets/services/borg.yaml;
            };
          };
        };

        environment = {
          systemPackages = lib.flatten (lib.mapAttrsToList mkRestoreScripts cfg.restores);
        };
      };
    };

    # NOTE: In keyfile mode the key only exists in ~/.config/borg/keys,
    #       losing it makes every archive unreadable.
    nixosModules.borgPersistent = {
      preservation = {
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/root/.config/borg";
              mode = "0700";
            }
            {
              directory = "/root/.cache/borg";
              mode = "0700";
            }
          ];
        };
      };
    };
  };
}
