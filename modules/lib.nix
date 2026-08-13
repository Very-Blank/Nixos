{
  flake.lib = {
    mkCombinedModule = {
      options ? {},
      nixosModule,
      homeModule,
    }: user:
      assert builtins.isString user;
        {...}: {
          imports = [nixosModule];

          inherit options;

          config = {
            home-manager.users."${user}" = homeModule;
          };
        };

    mkUserModule = user:
      assert builtins.isString user;
        {
          options ? {},
          nixosModule,
          homeModule,
        }: {...}: {
          imports = [(nixosModule user)];

          inherit options;

          config = {
            home-manager.users."${user}" = homeModule user;
          };
        };
  };
}
