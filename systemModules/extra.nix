{ ... }: 

{
  services = {
    blueman.enable = true;

    actkbd = {
      enable = true;
      bindings = [
        { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 5"; }
        { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 5"; }
      ];
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    tuxedo-rs = {
      enable = true;
      tailor-gui.enable = true;
    };

    tuxedo-drivers.enable = true;
  };
  
  programs = {
    light = {
      enable = true;
    };
  };
}
