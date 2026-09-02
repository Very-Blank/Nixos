{
  flake = {
    nixosModules.greeter = {
      lib,
      pkgs,
      config,
      ...
    }: {
      options = {
        modules = {
          greeter = {
            commands = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  user = lib.mkOption {
                    type = lib.types.nonEmptyStr;
                  };

                  cmd = lib.mkOption {
                    type = lib.types.nonEmptyStr;
                    description = "The command that will be run for this user.";
                  };
                };
              });
            };
          };
        };
      };

      config = let
        cfg = config.modules.greeter;
      in {
        assertions = [
          {
            assertion = lib.lists.allUnique (map (command: command.user) cfg.commands);
            message = ''
              The greeter nixos module has duplicate users in the config.
              All user must be unique as it can't pick multiple commands for the same user.
            '';
          }
        ];

        services = {
          getty = {
            greetingLine = "<< NixOS ${config.system.nixos.release} >>\n";
            helpLine = let
              name = config.core.host.name;
            in
              lib.mkForce (
                (lib.strings.toUpper (builtins.substring 0 1 name))
                + (builtins.substring 1 (builtins.stringLength name) name)
                + " at your service."
              );
          };

          greetd = {
            enable = true;
            useTextGreeter = true;

            settings = {
              terminal = {
                vt = 1;
              };

              default_session = let
                commands = map (command: "${command.user}) exec ${command.cmd} ;;") cfg.commands;

                chooser = pkgs.writeShellScript "session-chooser" ''
                  case "$(id -un)" in
                    ${lib.strings.concatLines commands}
                    *) exec $SHELL ;;
                  esac
                '';
              in {
                command = "${lib.getExe' pkgs.greetd "agreety"} --max-failures 3 --cmd '${chooser}'";
                user = "greeter";
              };

              # initial_session = lib.mkIf cfg.autoLogin {
              #   command = cfg.cmd;
              #   user = config.modules.home.user.name;
              # };
            };
          };
        };
      };
    };
  };
}
