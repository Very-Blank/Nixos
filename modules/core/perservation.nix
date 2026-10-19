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
              "/var/lib/NetworkManager"
              "/var/lib/systemd/timers"
              "/var/lib/systemd/coredump"
              "/var/lib/systemd/random-seed"
              "/etc/NetworkManager/system-connections"
              {
                directory = "/tmp";
                mode = "1777";
              }
              {
                directory = "/var/lib/nixos";
                inInitrd = true;
              }
            ];

            files = [
              {
                file = "/var/lib/sops/age/keys.txt";
                inInitrd = true;
                mode = "0600";
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
