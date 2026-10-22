{inputs, ...}: {
  flake = {
    nixosModules.disko = {
      lib,
      config,
      ...
    }: {
      imports = [inputs.disko.nixosModules.disko];

      options = {
        core = {
          disko = {
            diskId = lib.mkOption {
              description = "The id of the main disk used for the nixos install.";
              type = lib.types.nonEmptyStr;
            };
          };
        };
      };

      config = let
        cfg = config.core.disko;
      in
        lib.mkIf (config.core.host.type == "live") {
          fileSystems = {
            "/nix".neededForBoot = true;
            "/persistent".neededForBoot = true;
          };

          disko.devices = {
            nodev = {
              "/" = {
                fsType = "tmpfs";
                mountOptions = [
                  "size=25%"
                  "mode=755"
                ];
              };
            };

            disk.main = {
              device = "/dev/disk/by-id/${cfg.diskId}";
              type = "disk";

              content = {
                type = "gpt";
              };

              content = {
                partitions = {
                  boot = {
                    name = "boot";
                    size = "1M";
                    type = "EF02";
                  };

                  esp = {
                    name = "ESP";
                    size = "1G";
                    type = "EF00";

                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                    };
                  };

                  swap = {
                    size = "8G";

                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  };

                  root = {
                    name = "root";
                    size = "100%";

                    content = {
                      type = "btrfs";
                      extraArgs = ["-f"];

                      subvolumes = {
                        "/persistent" = {
                          mountOptions = ["subvol=persistent" "noatime"];
                          mountpoint = "/persistent";
                        };

                        "/nix" = {
                          mountOptions = ["subvol=nix" "noatime"];
                          mountpoint = "/nix";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
    };
  };
}
