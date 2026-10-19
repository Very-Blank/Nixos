{self, ...}: {
  flake = {
    nixosConfigurations.hermesVM = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.hermes
        self.nixosModules.hermesHardware
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

    nixosConfigurations.hermes = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.hermes
        self.nixosModules.hermesHardware
      ];
    };

    nixosModules.hermes = {pkgs, ...}: {
      imports = with self.nixosModules; [
        systemdBoot
        tuxedo
        greeter
        networking
        audio
        blank
      ];

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

      services = {
        upower.enable = true;
        power-profiles-daemon.enable = true;
      };

      core = {
        host = {
          name = "hermes";

          outputs = {
            "BOE 0x0C8E Unknown" = {
              mode = {
                width = 2560;
                height = 1600;
                refresh = 240.000;
              };

              scale = 1.5;
            };
          };
        };

        disko = {
          diskId = "nvme-Samsung_SSD_980_500GB_S78GNL0Y338093Z";
        };
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

      system = {
        stateVersion = "26.11";
      };
    };

    nixosModules.hermesHardware = {
      lib,
      config,
      modulesPath,
      ...
    }: {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];
      boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" "sdhci_pci"];
      boot.initrd.kernelModules = [];
      boot.kernelModules = ["kvm-amd"];
      boot.extraModulePackages = [];
      networking.useDHCP = lib.mkDefault true;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
