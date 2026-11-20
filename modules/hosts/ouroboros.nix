{self, ...}: {
  flake = {
    nixosConfigurations.ouroborosVM = self.lib.mkNixosSystem {
      modules = [
        self.nixosModules.ouroboros
        self.nixosModules.ouroborosHardware
        self.nixosModules.vm
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
        sillysnake
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
          users = {
            sillysnake = {
              authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGU4pH0jqPg+3y2k0OqKhFZyw5MvQ7Z3y9A85QK2cNPu hermes"
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJGMpg3Izk3qIBUIRmMTR6YF2uwnHY1xr1xU2pi4ftX zaratul"
              ];
            };
          };

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
