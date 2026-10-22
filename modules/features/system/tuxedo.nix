{
  flake.nixosModules.tuxedo = {
    hardware = {
      # FIXME: This is waiting for https://github.com/NixOS/nixpkgs/issues/576266
      # tuxedo-drivers.enable = true;

      # tuxedo-rs = {
      #   enable = true;
      #   tailor-gui.enable = true;
      # };
    };
  };
}
