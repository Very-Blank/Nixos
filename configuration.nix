{pkgs, lib, ... }:
{
  imports = [
    ./systemModules/niri.nix
    ./systemModules/waybar.nix
    ./systemModules/hardware-configuration.nix
    ./systemModules/boot.nix
    ./systemModules/extra.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];


  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 2d";
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Helsinki";

  services = {
    displayManager.sddm = {
      enable = true;
      theme = "catppuccin-macchiato";

      wayland = {
        enable = true;
        compositor = "weston";
      };

      settings = {
        Theme = {
          Current = "catppuccin-macchiato";
          CursorTheme = "Bibata-Original-Classic";
          CursorSize = 16;
        };
      };

      package = pkgs.kdePackages.sddm;
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
      audio.enable = true;

      alsa = {
        enable = true;
        support32Bit = true; 
      };

      jack.enable = true;
    };

    openssh.enable = true;
  };

  users.users.blank = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "bluetooth" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };

  programs = {
    zsh = {
      enable = true;
    };

    tmux = {
      enable = true;
      escapeTime = 0;
      keyMode = "vi";
      extraConfig = ''
        set-option -g default-shell $SHELL
        set -g prefix C-a
        unbind C-b
        bind C-a send-prefix
      '';
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
  };

  environment.systemPackages = [
    (pkgs.catppuccin-sddm.override {
      flavor = "macchiato";
      font  = "0xProto Nerd Mono Font";
      fontSize = "14";
      # background = "${./wallpaper.png}";
      loginBackground = true;
    })
    pkgs.home-manager
    pkgs.vim
    pkgs.wget
    pkgs.unzip
    pkgs.seatd
    pkgs.pavucontrol
  ];

  fonts = {
    packages = [
      pkgs.jetbrains-mono
      pkgs.noto-fonts
      pkgs.noto-fonts-emoji
      pkgs.twemoji-color-font
      pkgs.font-awesome
      pkgs.powerline-fonts
      pkgs.powerline-symbols
      pkgs.nerd-fonts._0xproto
    ];
  };

  system.stateVersion = "24.11";
}

