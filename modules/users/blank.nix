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
          packages = [
            self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
            (self.packages.${pkgs.stdenv.hostPlatform.system}.git.override {
              user = {
                email = "aapeli.saarelainen.76@gmail.com";
                name = "very-blank";
              };
            })
          ];

          programs.ssh = {
            enable = true;

            settings = {
              "github.com" = {
                HostName = "github.com";
                User = "very-blank";
                IdentityFile = "~/.ssh/github";
              };

              "taildevourer.com" = {
                HostName = "taildevourer.com";
                User = "blank";
                IdentityFile = "~/.ssh/taildevourer";
              };

              "gitlab.jyu.fi" = {
                HostName = "gitlab.jyu.fi";
                User = "blank";
                IdentityFile = "~/.ssh/gitlab";
              };
            };
          };

          stateVersion = "26.11";
        };
      };
    };
  };
}
