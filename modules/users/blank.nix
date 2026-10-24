{self, ...}: {
  flake = {
    nixosModules.blank = let
      user = "blank";
    in
      {
        lib,
        pkgs,
        config,
        ...
      }: let
        niri = self.packages.${pkgs.stdenv.hostPlatform.system}.niri.override {
          outputs = config.core.host.outputs;
          audio = builtins.elem "audio" config.core.host.features;
          brightness = builtins.elem "audio" config.core.host.features;

          terminal = "${
            lib.getExe
            (
              if (config.core.host.name == "hermes")
              then
                # NOTE: On hermes this helps out to fill the whole terminal emulator.
                (self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty.override {
                  cellAdjust = {
                    height = "-25%";
                    width = "-20%";
                  };
                })
              else self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty
            )
          }";

          launcher = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun}";

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

          packages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
            librewolf
            nvim
            (git.override {
              user = {
                email = "aapeli.saarelainen.76@gmail.com";
                name = "very-blank";
              };
            })
            (ssh.override {
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
                  user = "aapotska";
                }
              ];
            })
          ];
        };

        core = {
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
                ".local/share/keyrings"
                ".local/share/Nextcloud"
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
