{self, ...}: {
  flake = let
    user = "blank";
  in {
    nixosModules.${user} = {
      lib,
      pkgs,
      config,
      ...
    }: let
      packages = self.packages.${pkgs.stdenv.hostPlatform.system};

      niri = packages.niri.override {
        outputs = config.core.host.outputs;
        audio = builtins.elem "audio" config.core.host.features;
        brightness = builtins.elem "brightness" config.core.host.features;
        terminal = "${lib.getExe packages.ghostty}";
        launcher = "${lib.getExe packages.anyrun}";

        screenshots = {
          path = "~/Pictures/Screenshots/";
          format = "screenshot_%Y-%m-%d_%Hh%Mm%Ss.png";
        };
      };
    in {
      imports = lib.concatLists [
        [
          self.nixosModules.steam
          self.nixosModules.niri
        ]
        (map (m: m user) (with self.userModules; [
          gtk

          networkingTrayService
          bluetoothTrayService
          quickshellService
          anyrunService
          swaybgService
          makoService

          librewolfPersistent
          steamPersistent
          audioPersistent
        ]))
      ];

      sops = {
        secrets = {
          "users/${user}/password-hash" = lib.mkIf (config.core.host.type == "live") {
            sopsFile = ../../secrets/users/${user}.yaml;
            neededForUsers = true;
          };
        };
      };

      users.users.${user} = {
        shell = packages.zsh;

        hashedPasswordFile = lib.mkIf (config.core.host.type == "live") config.sops.secrets."users/${user}/password-hash".path;
        password = lib.mkIf (config.core.host.type == "vm") "test";

        isNormalUser = true;

        extraGroups = [
          "wheel"
          "video"
          "input"
          "audio"
        ];

        packages = with packages; [
          librewolf

          nvim
          (git.override {
            core = {
              editor = "nvim";
            };

            user = {
              name = "very-blank";
              email = "aapeli.saarelainen.76@gmail.com";
            };
          })
          (ssh.override {
            hosts = [
              {
                match = "github.com";
                name = "github.com";
                user = "very-blank";
                identityFile = "~/.ssh/github";
              }

              # TODO: Change user to "sillysnake" once ouroboros is reinstalled with the new config.
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
                user = "aapotska";
              }
            ];
          })
        ];
      };

      core = {
        greeter = {
          users.${user} = let
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
              ".local/share/keyrings"
              ".local/share/Nextcloud"
              ".local/share/zoxide"
              ".ssh"
            ];

            files = [
              ".zsh_history"
            ];
          };
        };
      };

      # NOTE: This is required for zsh's autocompletions to work.
      # FIXME: Move this else where?
      environment.pathsToLink = ["/share/zsh"];
    };
  };
}
