{self, ...}: {
  flake = {
    nixosModules.blank = self.lib.mkUserModule "blank" {
      nixosModule = user: {pkgs, ...}: {
        imports = [
          self.nixosModules.steam
          self.nixosModules.niri
        ];

        core = {
          unfree = {
            packages = [
              "obsidian"
            ];
          };
        };

        users.users."${user}" = {
          shell = self.packages.${pkgs.stdenv.hostPlatform.system}.zsh;

          extraGroups = [
            "wheel"
            "video"
            "input"
            "audio"
          ];
        };

        # NOTE: This is required for zsh's autocompletions to work.
        environment.pathsToLink = ["/share/zsh"];
      };

      homeModule = user: {
        lib,
        pkgs,
        ...
      }: {
        imports = with self.homeModules; [
          greeter
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

        modules = {
          greeter = {
            cmd = "${lib.getExe' (self.packages.niri.override {
              niri = let
              in {
                audio = true;
                brightness = true;
                terminal = "${lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.ghostty "ghostty"}";
                launcher = "${lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.anyrun "anyrun"}";

                screenshots = {
                  path = "~/Pictures/Screenshots/";
                  format = "screenshot_%Y-%m-%d_%Hh%Mm%Ss.png";
                };
              };
            }) "niri"}";
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
            pkgs.obsidian
            self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
          ];
          stateVersion = "26.11";
        };
      };
    };
  };
}
