{inputs, ...}: {
  flake = {
    nixosModules.sops = {
      lib,
      config,
      ...
    }: {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      # NOTE: For VMs secrects aren't enabled.
      sops = lib.mkIf (config.core.host.type == "live") {
        age.keyFile = "/var/lib/sops/age/keys.txt";
      };
    };
  };
}
