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

        sops.secrets."users/${user}/password-hash" = {
          sopsFile = ../../secrets/users/. + "/${user}.yaml";
          neededForUsers = true;
        };

        users.users."${user}" = {
          shell = self.packages.${pkgs.stdenv.hostPlatform.system}.zsh;

          hashedPasswordFile = config.sops.secrets."users/${user}/password-hash".path;
          isNormalUser = true;

          extraGroups = [
            "wheel"
            "video"
            "input"
            "audio"
          ];
        };

        modules = {
          greeter = {
            users."${user}" = "${lib.getExe' niri "niri-session"}";
          };
        };

        systemd.packages = [niri];

        # NOTE: This is required for zsh's autocompletions to work.
        environment.pathsToLink = ["/share/zsh"];
      };

      homeModule = user: {pkgs, ...}: {
        imports = with self.homeModules; [
          networkingTrayService
          bluetoothTrayService
          anyrunService
          waybarService
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

        programs = {
          git = {
            enable = true;

            settings = {
              init = {
                defaultBranch = "main";
              };

              core.editor = "nvim";

              user = {
                name = "very-blank";
                email = "aapeli.saarelainen.76@gmail.com";
              };
            };
          };
        };

        home = {
          packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
          ];
          stateVersion = "26.11";
        };
      };
    };
  };
}
