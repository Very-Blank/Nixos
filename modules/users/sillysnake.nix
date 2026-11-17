{
  flake = {
    # NOTE: Minimal user for servers, only what's needed to log in and administrate.
    nixosModules.sillysnake = let
      user = "sillysnake";
    in
      {
        lib,
        config,
        ...
      }: {
        sops = {
          secrets = {
            "users/${user}/password-hash" = lib.mkIf (config.core.host.type == "live") {
              sopsFile = ../../secrets/users/${user}.yaml;
              neededForUsers = true;
            };
          };
        };

        users = {
          users = {
            ${user} = {
              hashedPasswordFile = lib.mkIf (config.core.host.type == "live") config.sops.secrets."users/${user}/password-hash".path;
              password = lib.mkIf (config.core.host.type == "vm") "test";

              isNormalUser = true;

              extraGroups = [
                "wheel"
              ];
            };
          };
        };
      };
  };
}
