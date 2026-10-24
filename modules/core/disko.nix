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
            main = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "The id of the main disk used for the nixos install.";
            };

            extra = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  id = lib.mkOption {
                    type = lib.types.nonEmptyStr;
                    description = "The id of the extra disk.";
                  };

                  mountpoint = lib.mkOption {
                    type = lib.types.nonEmptyStr;
                    description = "The mountpoint of the extra disk.";
                  };
                };
              });

              default = {};
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
                  "size=50%"
                  "mode=755"
                ];
              };
            };

            disk = lib.mkMerge [
              (lib.concatLists
                [
                  {
                    main = {
                      device = "/dev/disk/by-id/${cfg.main}";
                      type = "disk";

                      content = {
                        type = "gpt";

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
                                  mountpoint = "/persistent";
                                  mountOptions = ["subvol=persistent" "noatime"];
                                };

                                "/nix" = {
                                  mountpoint = "/nix";
                                  mountOptions = ["subvol=nix" "noatime"];
                                };
                              };
                            };
                          };
                        };
                      };
                    };
                  }
                ]
                (lib.mapAttrs (name: opts: {
                    ${name} = {
                      device = "/dev/disk/by-id/${opts.id}";
                      type = "disk";

                      content = {
                        type = "gpt";
                        partitions = {
                          games = {
                            size = "100%";
                            content = {
                              type = "filesystem";
                              format = "ext4";
                              mountpoint = opts.mountpoint;
                              mountOptions = ["noatime" "nofail"];
                            };
                          };
                        };
                      };
                    };
                  })
                  cfg.extra))
            ];
          };
        };
    };
  };
}
