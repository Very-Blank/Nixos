{self, ...}: {
  flake = {
    combinedModules.zsh = self.lib.mkCombinedModule {
      nixosModule = user: {pkgs, ...}: {
        programs.zsh = {
          enable = true;
        };

        users = {
          users.${user} = {
            shell = pkgs.zsh;
          };
        };

        environment.pathsToLink = ["/share/zsh"];
      };

      homeModule = _: {
        pkgs,
        osConfig,
        ...
      }: {
        programs.zsh = {
          enable = true;

          enableCompletion = true;
          autosuggestion.enable = true;
          autosuggestion.highlight = "fg=magenta";

          syntaxHighlighting.enable = true;

          defaultKeymap = "viins";

          shellAliases = {
            ns = "nix-shell --run zsh";
            build-switch = "sudo nixos-rebuild switch --flake .#${osConfig.core.host.name}";

            ls = "ls --color=auto -h --group-directories-first";
            ll = "ls -l";
            rr = "rm -r";

            gca = "git commit -a";
            gc = "git checkout";
            grm = "git rebase main";
            gcb = "git checkout -b";
            gsm = "git push origin main";
            glm = "git pull origin main";

            hibernate = "systemctl hibernate";
          };

          history.size = 10000;

          initContent = ''
            fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
            autoload -U promptinit && promptinit
            prompt pure

            bindkey '^Y' autosuggest-accept
          '';
        };
      };
    };
  };
}
