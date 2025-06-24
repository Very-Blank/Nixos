{nvim, pkgs, ...}:

{
  home.packages = [
    pkgs.lua-language-server
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  xdg.configFile."nvim" = {
    enable = true;
    source = nvim;
  };
}
