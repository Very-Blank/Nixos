{pkgs, ...}:
{
  programs = {
    waybar = {
      enable = true;
    };
  };

  environment.systemPackages = [
    pkgs.libappindicator
    pkgs.networkmanagerapplet
  ];
}
