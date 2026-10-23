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

    nixosModules.zaratul = {pkgs, ...}: {
      imports = with self.nixosModules; [
        grubBoot
        greeter
        networking
        audio
        blank
      ];

      modules = {
        grub = {
          boot = "multi";
        };
      };

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
                x = 2327;
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

              scale = 1.1;

              position = {
                x = 0;
                y = 0;
              };
            };
          };
        };

        disko = {
          diskId = "nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0W429881M";
        };
      };

      users = {
        mutableUsers = false;
      };

      programs = {
        nano.enable = false;
        vim.enable = true;
      };

      environment.systemPackages = [
        pkgs.wget
        pkgs.unzip
      ];

      system = {
        stateVersion = "26.11";
      };

      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 2d";
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
