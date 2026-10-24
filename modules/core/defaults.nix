{
  flake = {
    nixosModules.defaults = {
      lib,
      pkgs,
      ...
    }: {
      time = {
        timeZone = lib.mkDefault "Europe/Helsinki";
      };

      users = {
        mutableUsers = lib.mkDefault false;
      };

      programs = {
        nano.enable = false;
        vim.enable = true;
      };

      environment = {
        systemPackages = lib.mkForce [
          pkgs.wget
          pkgs.unzip
          pkgs.tree
          pkgs.rsync
        ];

        defaultPackages = lib.mkForce [];
      };

      nix = {
        settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 2d";
        };
      };

      system = {
        stateVersion = "26.11";
      };
    };
  };
}
