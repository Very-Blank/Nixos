{ pkgs, lib, ... }:

{
  home = {
    username = "blank";
    homeDirectory = "/home/blank";

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "obsidian"
    ];

    packages = [
      pkgs.cmake
      pkgs.zig
      pkgs.git
      pkgs.bibata-cursors
      pkgs.rustc
      pkgs.cargo
      pkgs.gcc
      pkgs.neofetch
      pkgs.python3
      pkgs.gnumake
      pkgs.godot
      pkgs.obsidian
    ];

    pointerCursor = {
      name = "Bibata-Original-Classic";
      package = pkgs.bibata-cursors;
      size = 16;
      gtk.enable = true;
      x11.enable = true;
    };

    sessionVariables = {
      XCURSOR_THEME = "Bibata-Original-Classic";
      XCURSOR_SIZE = "16";
    };

    stateVersion = "24.11";
  };
  
  programs.home-manager.enable = true;

  imports = [
    ./homeModules/git.nix
    ./homeModules/waybar/waybar.nix
    ./homeModules/niri/niri.nix
    ./homeModules/zsh.nix
    ./homeModules/mako.nix
    ./homeModules/fuzzel.nix
    ./homeModules/swaybg/swaybg.nix
    ./homeModules/ghostty.nix
    ./homeModules/firefox.nix
    ./homeModules/nvim/nvim.nix
    ./homeModules/stylix.nix
  ];

  xdg = {
    userDirs.createDirectories = true;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    # theme = {
    #   name = "Catppuccin-macchiato-blue-compact";
    #   package = pkgs.magnetic-catppuccin-gtk;
    # };
  };
}
