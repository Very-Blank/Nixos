{
  flake.lib = {
    mkCombinedModule = {
      nixosModule,
      homeModule,
    }: user:
      assert builtins.isString user;
        {...}: {
          imports = [(nixosModule user)];

          config = {
            home-manager.users."${user}" = homeModule user;
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
