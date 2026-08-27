{self, ...}: {
  flake = {
    combinedModules.obsidian = self.lib.mkCombinedModule {
      nixosModule = _: {
        features.unfree.packages = [
          "obsidian"
        ];
      };

      homeModule = _: {pkgs, ...}: {
        home.packages = [pkgs.obsidian];
      };
    };
  };
}
