{lib, ...}:

{
  
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        icon-theme = "Papirus";
        width = 40;
        font = lib.mkForce "0xProtoNerdFont:weight=normal:size=14";
        line-height = 15;
        vertical-pad = 8;
        horizontal-pad = 20;
        prompt = "\"❯ \"";
        exit-on-keyboard-focus-loss = "yes";
      };

      border = {
        radius = 20;
      };

      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };
}
