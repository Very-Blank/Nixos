{
  flake = {
    nixosModules.audio = {
      core.host.features = ["audio"];

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

    userModules.audioPersistent = user: {
      lib,
      config,
      ...
    }: {
      preservation = lib.mkIf (builtins.elem "audio" config.core.host.features) {
        preserveAt."/persistent" = {
          users.${user} = {
            files = [
              ".local/state/wireplumber/default-nodes"
            ];
          };
        };
      };
    };
  };
}
