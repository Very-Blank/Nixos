{
  flake.lib = {
    mkCombinedModule = {
      nixosModule,
      homeModule,
    }: user:
      assert builtins.isString user;
        {...}: {
          imports = [nixosModule];

          config = {
            home-manager.users."${user}" = homeModule;
          };
        };

    mkUserModule = user:
      assert builtins.isString user;
        {
          nixosModule,
          homeModule,
        }: {...}: {
          imports = [(nixosModule user)];

          config = {
            home-manager.users."${user}" = homeModule user;
          };
        };
  };
}
