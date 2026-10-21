{self, ...}: {
  flake = {
    nixosModules.blank = let
      user = "blank";
    in
      {
        lib,
        self',
        pkgs,
        config,
        ...
      }: let
        niri = self'.packages.niri.override {
          outputs = config.core.host.outputs;
          audio = true;
          brightness = true;
          terminal = "${lib.getExe self'.packages.ghostty}";
          launcher = "${lib.getExe self'.packages.anyrun}";

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
          shell = self'.packages.zsh;

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
            self'.packages.firefox
            self'.packages.nvim
            (self'.packages.git.override {
              user = {
                email = "aapeli.saarelainen.76@gmail.com";
                name = "very-blank";
              };
            })
            (self'.packages.ssh.override {
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
                ".ssh/know_hosts"
                ".local/share/keyrings"
                ".local/share/Nextcloud"
              ];

              files = [
                ".zsh_history"
                {
                  file = ".ssh/github";
                  mode = "600";
                }
                {
                  file = ".ssh/github.pub";
                  mode = "644";
                }

                {
                  file = ".ssh/taildevourer";
                  mode = "600";
                }
                {
                  file = ".ssh/taildevourer.pub";
                  mode = "644";
                }

                {
                  file = ".ssh/gitlab";
                  mode = "600";
                }
                {
                  file = ".ssh/gitlab.pub";
                  mode = "644";
                }
              ];
            };
          };
        };

        # NOTE: This is required for zsh's autocompletions to work.
        # FIXME: Move this else where?
        environment.pathsToLink = ["/share/zsh"];
      };

    # homeModule = user: {...}: {
    #   imports = with self.homeModules; [
    #     networkingTrayService
    #     bluetoothTrayService
    #     quickshellService
    #     anyrunService
    #     swaybgService
    #     makoService
    #     gtk
    #     obs
    #   ];
    #
    #   services = {
    #     nextcloud-client = {
    #       enable = true;
    #     };
    #   };
    #
    #   xdg = {
    #     enable = true;
    #
    #     userDirs = {
    #       createDirectories = true;
    #     };
    #   };
    #
    #   home = {
    #     stateVersion = "26.11";
    #   };
    # };
  };
}
