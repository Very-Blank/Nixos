{self, ...}: {
  flake.nixosConfigurations.zaratul = self.lib.mkNixosSystem {
    modules = [
      self.nixosModules.zaratul
      self.nixosModules.zaratulHardware
    ];
  };

  flake.nixosModules.zaratul = {pkgs, ...}: {
    imports = [
      self.nixosModules.grubBoot
      self.nixosModules.greeter
      self.nixosModules.blank
    ];

    modules = {
      grub = {
        boot = "multi";
      };
    };

    core = {
      host = {
        name = "zaratul";
      };
    };

    users = {
      mutableUsers = false;
    };

    environment.systemPackages = [
      pkgs.vim
      pkgs.firefox
    ];

    system.stateVersion = "26.11";
  };

  flake.nixosModules.zaratulHardware = {
    config,
    lib,
    pkgs,
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

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/dfe804d1-aa90-438d-a6c3-b79178bbf595";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/32B9-47AA";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/32a59dc6-43b6-412a-9293-5deb18872c4b";}
    ];

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
    # networking.interfaces.enp0s20f0u1.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
