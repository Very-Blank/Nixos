{inputs, pkgs, ...}:
{
  nixpkgs.overlays = [inputs.niri.overlays.niri];
  programs.niri.package = pkgs.niri-stable;

  programs.niri = {
    enable = true;
  };

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gnome
      pkgs.wtype
      pkgs.wl-clipboard
      pkgs.wayland-utils
      pkgs.libsecret
      pkgs.cage
      pkgs.gamescope
      pkgs.xwayland-satellite-unstable
      pkgs.swaybg
      pkgs.mako
    ];
  };
}
