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

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/6cb815ac-6412-4d1b-88a6-7c970556f072";
        fsType = "ext4";
      };

      swapDevices = [
        {device = "/dev/disk/by-uuid/376b9def-b1ce-4aa8-b991-4b0e2836be89";}
      ];

      # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
      # (the default) this is the recommended approach. When using systemd-networkd it's
      # still possible to use this option, but it's recommended to use it in conjunction
      # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
      networking.useDHCP = lib.mkDefault true;
      # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
