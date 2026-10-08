{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.nvim = inputs.nixnvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
