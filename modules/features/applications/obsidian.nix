{self, ...}: {
  flake = {
    combinedModules.obsidian = self.lib.mkCombinedModule {
      nixosModule = _: {
        core.unfree.packages = [
          "obsidian"
        ];
      };

      homeModule = _: {pkgs, ...}: {
        home.packages = [pkgs.obsidian];
      };
    };
  };
}
