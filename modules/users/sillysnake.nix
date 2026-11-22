{self, ...}: {
  flake = let
    user = "sillysnake";
  in {
    # NOTE: Minimal user for servers, only what's needed to log in and administrate.
    nixosModules.${user} = {
      lib,
      pkgs,
      config,
      ...
    }: let
      packages = self.packages.${pkgs.stdenv.hostPlatform.system};
    in {
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
            shell = packages.zsh;

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
