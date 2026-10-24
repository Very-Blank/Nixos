{self, ...}: {
  flake = {
    nixosConfigurations.zaratulVM = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.zaratul
        self.nixosModules.zaratulHardware
        {
          virtualisation.vmVariant = {
            virtualisation = {
              memorySize = 4096;
              cores = 4;
              qemu.options = [
                "-device virtio-vga-gl"
                "-display gtk,gl=on"
              ];
            };
          };

          hardware.graphics.enable = true;

          core.host.type = "vm";
        }
      ];
    };

    nixosConfigurations.zaratul = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.zaratul
        self.nixosModules.zaratulHardware
      ];
    };

    nixosModules.zaratul = {...}: {
      imports = with self.nixosModules; [
        networking
        audio
        blank
      ];

      core = {
        host = {
          name = "zaratul";

          outputs = {
            "PNP(AOC) 2590G5 0x00002709" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 74.973;
              };

              position = {
                x = 2560;
                y = 0;
              };
            };

            "PNP(AOC) Q27G3XMN 1APRBJA000045" = {
              main = true;

              mode = {
                width = 2560;
                height = 1440;
                refresh = 180.002;
              };

              scale = 1.25;

              position = {
                x = 0;
                y = 0;
              };
            };
          };
        };

        disko = {
          main = "nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0W429881M";

          extra = {
            games = {
              id = "nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0W429884H";
              mountpoint = "/games";
            };

            extra = {
              id = "wwn-0x5000c500b1579198";
              mountpoint = "/extra";
            };
          };
        };
      };
    };

    nixosModules.zaratulHardware = {
      lib,
      config,
      modulesPath,
      ...
    }: {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = ["vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
      boot.initrd.kernelModules = [];
      boot.kernelModules = ["kvm-intel"];
      boot.extraModulePackages = [];

      networking.useDHCP = lib.mkDefault true;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
