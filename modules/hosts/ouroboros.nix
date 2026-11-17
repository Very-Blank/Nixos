{self, ...}: {
  flake = {
    nixosConfigurations.ouroborosVM = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.ouroboros
        self.nixosModules.ouroborosHardware
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

    nixosConfigurations.ouroboros = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.ouroboros
        self.nixosModules.ouroborosHardware
      ];
    };

    nixosModules.ouroboros = {
      imports = with self.nixosModules; [
        networking
        ignoreLid
        openssh
        cloudflareDyndns
        nginx
        nginxPersistent
        borg
        borgPersistent
        vaultwarden
        vaultwardenPersistent
        vaultwardenNginx
        vaultwardenBorg
        nextcloud
        nextcloudPersistent
        nextcloudNginx
        nextcloudBorg
      ];

      core = {
        host = {
          name = "ouroboros";
          domain = "taildevourer.com";
        };

        disko = {
          main = "";
        };
      };

      features = {
        openssh = {
          banner = ''

             ██████╗ ██╗   ██╗██████╗  ██████╗ ██████╗  ██████╗ ██████╗  ██████╗ ███████╗
            ██╔═══██╗██║   ██║██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗██╔════╝
            ██║   ██║██║   ██║██████╔╝██║   ██║██████╔╝██║   ██║██████╔╝██║   ██║███████╗
            ██║   ██║██║   ██║██╔══██╗██║   ██║██╔══██╗██║   ██║██╔══██╗██║   ██║╚════██║
            ╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝██████╔╝╚██████╔╝██║  ██║╚██████╔╝███████║
             ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
                                       A private ssh service.
                                       Authorized users only,
                                             thank you.

          '';
        };

        nginx = {
          acme = {
            email = "aapeli.saarelainen.76@gmail.com";
          };
        };

        borg = {
          repo = name: "ssh://u561700@u561700.your-storagebox.de:23/./${name}";

          environment = {
            BORG_RSH = "ssh -i /root/.ssh/hetzner";
          };
        };
      };

      programs.ssh.knownHosts = {
        hetzner-storagebox = {
          hostNames = ["[u561700.your-storagebox.de]:23"];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        };
      };

      preservation = {
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/root/.ssh";
              mode = "0700";
            }
          ];
        };
      };
    };

    nixosModules.ouroborosHardware = {
      lib,
      config,
      modulesPath,
      ...
    }: {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
      boot.initrd.kernelModules = [];
      boot.kernelModules = ["kvm-amd"];
      boot.extraModulePackages = [];
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
