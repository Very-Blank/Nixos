{inputs, ...}: {
  flake = {
    nixosModules.perservation = {
      lib,
      config,
      ...
    }: {
      imports = [
        inputs.preservation.nixosModules.default
      ];

      config = lib.mkIf (config.core.host.type == "live") {
        preservation = {
          enable = true;

          preserveAt."/persistent" = {
            directories = [
              "/var/log"
              "/var/lib/bluetooth"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/etc/NetworkManager/system-connections"
              "/tmp"
              {
                directory = "/var/lib/nixos";
                inInitrd = true;
              }
            ];

            files = [
              {
                file = "/var/lib/sops/age/keys.txt";
                inInitrd = true;
              }
              {
                file = "/etc/machine-id";
                inInitrd = true;
              }
            ];
          };
        };
      };
    };
  };
}
