{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  config = {
    hostname = "zaratul";

    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
        brlaser
      ];
    };

    modules = {
      terminal = {
        tmux.enable = true;
        zsh.enable = true;
      };

      developer = {
        nvim.enable = true;
        nvim.defaultEditor = true;
        git.enable = true;
        ssh.enable = true;

        ssh.keys = [
          {
            match = "github.com";
            hostname = "github.com";
            user = "very-blank";
          }
          {
            match = "codeberg.org";
            hostname = "codeberg.org";
            user = "very-blank";
          }
          {
            match = "taildevourer.com";
            hostname = "taildevourer.com";
            user = "blank";
          }
          {
            match = "gitlab.jyu.fi";
            hostname = "gitlab.jyu.fi";
            user = "aapotska";
          }
        ];
      };

      desktop = {
        enable = true;
        windowManager = "niri";

        bar = {
          enable = true;
          modules = ["tray" "systemInfo"];
        };

        applications = [
          "steam"
          "obsidian"
          "obs"
          "nextcloud"
          "mumble"
        ];
      };

      graphical = {
        windowManagers = {
          niri = {
            outputs = {
              "PNP(AOC) 2590G5 0x00002709" = {
                mode = {
                  width = 1920;
                  height = 1080;
                  refresh = 74.973;
                };

                position = {
                  x = 1920;
                  y = 0;
                };
              };

              "Samsung Electric Company LS32AG32x H9JT200575   " = {
                mode = {
                  width = 1920;
                  height = 1080;
                  refresh = 143.998;
                };

                focus-at-startup = true;
                position = {
                  x = 0;
                  y = 0;
                };
              };
            };
          };
        };

        applications.other.obs = {
          hardwareAcceleration = "amd";
        };
      };

      hardware.audio.enable = true;

      boot = {
        multiboot = true;
      };
    };
  };
}
