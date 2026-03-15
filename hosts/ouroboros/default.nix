{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  config = {
    hostname = "ouroboros";

    services.upower.ignoreLid = true;
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    modules = {
      terminal = {
        tmux.enable = true;
        zsh.enable = true;
      };

      tty = {
        greetd = {
          enable = true;
          autoLogin = true;
        };
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
        ];
      };

      hardware = {
        backlight.enable = true;

        info = {
          battery = true;
        };
      };

      server = {
        openssh = {
          enable = true;
          keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGU4pH0jqPg+3y2k0OqKhFZyw5MvQ7Z3y9A85QK2cNPu hermes"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJGMpg3Izk3qIBUIRmMTR6YF2uwnHY1xr1xU2pi4ftX zaratul"
          ];
        };

        domain.main = "taildevourer.com";
        vaultwarden.enable = true;
        nextcloud.enable = true;
        ddclient.enable = true;

        borg = {
          enable = true;
          repo = "ssh://u561700@u561700.your-storagebox.de:23/./Backup";

          environment = {
            BORG_RSH = "ssh -i /home/blank/.ssh/hetzner";
          };
        };

        nginx = {
          enable = true;
          acme.email = "aapeli.saarelainen.76@gmail.com";
        };
      };
    };
  };
}
