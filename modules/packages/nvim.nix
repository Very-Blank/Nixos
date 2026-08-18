{
  self,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.nvim = inputs.nixnvim.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  flake = {
    homeModules.nvim = {pkgs, ...}: {
      programs.neovim = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.nvim;
      };

      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        SUDO_EDITOR = "nvim";
      };

      programs.git = {
        settings = {
          core.editor = "nvim";
        };
      };

      programs.bash = {
        bashrcExtra = ''
          export EDITOR="nvim"
          export VISUAL="nvim"
        '';
      };

      programs.zsh = {
        initContent = ''
          export EDITOR="nvim"
          export VISUAL="nvim"
        '';
      };
    };
  };
}
