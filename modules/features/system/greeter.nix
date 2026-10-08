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
            users = lib.mkOption {
              type = lib.types.attrsOf lib.types.nonEmptyStr;
              default = {};
              description = "Command to run for that user at login.";
            };
          };
        };
      };

      config = let
        cfg = config.modules.greeter;
      in {
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
                commands =
                  lib.mapAttrsToList
                  (user: cmd: "${lib.escapeShellArg user}) exec ${cmd} ;;")
                  cfg.users;

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
            };
          };
        };
      };
    };
  };
}
