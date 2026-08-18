{
  flake.nixosModules.audio = {
    services = {
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
    };
  };
}
