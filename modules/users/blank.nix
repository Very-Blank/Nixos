{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {
        config,
        pkgs,
        lib,
        ...
      }: let
        niri = self.packages.${pkgs.stdenv.hostPlatform.system}.niri.override {
          outputs = config.core.host.outputs;
          audio = true;
          brightness = true;
          terminal = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty}";
          launcher = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun}";

          screenshots = {
            path = "~/Pictures/Screenshots/";
            format = "screenshot_%Y-%m-%d_%Hh%Mm%Ss.png";
          };
        };
      in {
        imports = [
          self.nixosModules.steam
          self.nixosModules.niri
        ];

        sops.secrets."users/${user}/password-hash" = lib.mkIf (config.core.host.type == "live") {
          sopsFile = ../../secrets/users/. + "/${user}.yaml";
          neededForUsers = true;
        };

        users.users."${user}" = {
          shell = self.packages.${pkgs.stdenv.hostPlatform.system}.zsh;

          hashedPasswordFile = lib.mkIf (config.core.host.type == "live") config.sops.secrets."users/${user}/password-hash".path;
          password = lib.mkIf (config.core.host.type == "vm") "test";

          isNormalUser = true;

          extraGroups = [
            "wheel"
            "video"
            "input"
            "audio"
          ];

          packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
            (self.packages.${pkgs.stdenv.hostPlatform.system}.git.override {
              user = {
                email = "aapeli.saarelainen.76@gmail.com";
                name = "very-blank";
              };
            })
            (self.packages.${pkgs.stdenv.hostPlatform.system}.ssh.override {
              settings = [
                {
                  match = "github.com";
                  name = "github.com";
                  user = "very-blank";
                  identityFile = "~/.ssh/github";
                }

                {
                  match = "taildevourer.com";
                  name = "taildevourer.com";
                  identityFile = "~/.ssh/taildevourer";
                  user = "blank";
                }

                {
                  match = "gitlab.jyu.fi";
                  name = "gitlab.jyu.fi";
                  identityFile = "~/.ssh/gitlab";
                  user = "blank";
                }
              ];
            })
          ];
        };

        modules = {
          greeter = {
            users."${user}" = let
              niri-session = pkgs.writeShellScript "niri-session" ''
                if systemctl --user -q is-active niri.service; then
                  systemctl --user stop niri.service
                fi

                exec ${lib.getExe' niri "niri-session"}
              '';
            in "${niri-session}";
          };
        };

        systemd.packages = [niri];

        preservation = {
          preserveAt."/persistent" = {
            users.${user} = {
              directories = [
                "Nix"
                "Projects"
                "Nextcloud"
                "Downloads"
                "Pictures"
                ".mozilla"
              ];

              files = [
                ".ssh/github"
                ".ssh/taildevourer"
                ".ssh/gitlab"
              ];
            };
          };
        };

        # NOTE: This is required for zsh's autocompletions to work.
        # FIXME: Move this else where?
        environment.pathsToLink = ["/share/zsh"];
      };

      homeModule = user: {...}: {
        imports = with self.homeModules; [
          networkingTrayService
          bluetoothTrayService
          quickshellService
          anyrunService
          swaybgService
          makoService
          gtk
          firefox
          obs
        ];

        services = {
          nextcloud-client = {
            enable = true;
          };
        };

        xdg = {
          enable = true;

          userDirs = {
            createDirectories = true;
          };
        };

        home = {
          stateVersion = "26.11";
        };
      };
    };
  };
}
