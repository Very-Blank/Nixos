{
  flake = {
    # NOTE: For laptops that are used with the lid closed, e.g. as a server.
    nixosModules.ignoreLid = {
      services = {
        upower = {
          ignoreLid = true;
        };

        logind = {
          settings = {
            Login = {
              HandleLidSwitch = "ignore";
              HandleLidSwitchExternalPower = "ignore";
              HandleLidSwitchDocked = "ignore";
            };
          };
        };
      };
    };
  };
}
