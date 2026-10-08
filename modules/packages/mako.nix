{
  self,
  inputs,
  ...
}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.mako = lib.makeOverridable ({
      timeout ? 1500,
      border ? {
        radius = 10;
        size = 0;
      },
      font ? {
        package = pkgs.nerd-fonts._0xproto;
        size = 12;
        family = "0xProto Nerd Font";
      },
    }: let
      config = let
        palette = inputs.colors.lib.withHash self.globals.theme.palette;
      in ''
        default-timeout=${lib.toString timeout}
        border-radius=${lib.toString border.radius}
        border-size=${lib.toString border.size}

        font=${builtins.replaceStrings [" "] [""] font.family} ${lib.toString font.size}

        background-color=${palette.base00}FF
        border-color=${palette.base0D}
        text-color=${palette.base05}
        progress-color=over ${palette.base02}

        ["urgency=low"]
        background-color=${palette.base00}FF
        border-color=${palette.base03}
        text-color=${palette.base05}

        ["urgency=critical"]
        background-color=${palette.base00}FF
        border-color=${palette.base08}
        text-color=${palette.base05}
      '';

      fontConfig = self.lib.mkFontsConf pkgs font.package;
    in (pkgs.symlinkJoin {
      name = "mako";
      paths = [pkgs.mako];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--config ${pkgs.writeText "config" config}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/mako"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
          "--set FONTCONFIG_FILE ${fontConfig}"
        ];

      meta.mainProgram = "mako";
    })) {};
  };

  flake = {
    homeModules.makoService = {
      lib,
      pkgs,
      ...
    }: {
      systemd.user.services.mako = {
        Unit = {
          Description = "Mako service";
          PartOf = "graphical-session.target";
          After = "graphical-session.target";
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.mako "mako"}";
          Restart = "on-failure";
          RestartSec = "1s";
          KillMode = "process";
        };

        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };
    };
  };
}
