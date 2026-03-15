{
  lib,
  config,
  ...
}: {
  options = {
    modules = {
      server = {
        borg = {
          enable = lib.mkEnableOption "Enables the borg module.";

          repo = lib.mkOption {
            description = "Path to the repo.";
            type = lib.types.nonEmptyStr;
          };

          encryption = {
            mode = lib.mkOption {
              type = lib.types.enum [
                "keyfile"
                "keyfile-blake2"
              ];
              description = ''
                Encryption mode to use. Setting a mode
                other than `"none"` requires
                you to specify a {option}`passCommand`
                or a {option}`passphrase`.
              '';
              default = "keyfile";
              example = "keyfile-blake2";
            };

            passCommand = lib.mkOption {
              type = with lib.types; nullOr str;
              description = ''
                A command which prints the passphrase to stdout.
              '';
              example = "cat /path/to/passphrase_file";
            };
          };

          environment = lib.mkOption {
            type = with lib.types; attrsOf str;
            description = ''
              Environment variables passed to the backup script.
              You can for example specify which SSH key to use.
            '';
            example = {
              BORG_RSH = "ssh -i /path/to/key";
            };
          };
        };
      };
    };
  };

  config = let
    cfg = config.modules.server.borg;
  in
    lib.mkIf cfg.enable {
      sops.secrets = {
        "borg/password" = {
          sopsFile = ../../../secrets/other/. + "/${config.hostname}.yaml";
        };
      };

      cfg.passCommand = "cat ${config.sops.secrets."borg/password".path}";
    };
}
