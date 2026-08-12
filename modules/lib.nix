{
  flake.lib = {
    mkCombinedModule = {
      nixosModule,
      homeModule,
    }: user:
      assert builtins.isString user; {
        imports = [nixosModule];
        home-manager.users.${user}.imports = [homeModule];
      };
  };
}
