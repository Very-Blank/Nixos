{ pkgs, ... }:

{
  home = {
    username = "blank";
    homeDirectory = "/home/blank";
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
      pkgs.steam
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
    ./git.nix
    ./waybar/waybar.nix
    ./niri/niri.nix
    ./zsh.nix
    ./mako.nix
    ./fuzzel.nix
    ./swaybg/swaybg.nix
    ./ghostty.nix
    ./firefox.nix
    ./nvim/nvim.nix
    ./stylix.nix
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
