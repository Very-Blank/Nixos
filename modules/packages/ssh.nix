{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.ssh = lib.makeOverridable ({
      settings ? [
      ],
    }: let
      configFile = pkgs.writeText "config" (lib.strings.concatStringsSep "\n" (map (setting: ''
          Host ${setting.match}
            HostName ${setting.name}
            IdentityFile ${setting.identityFile}
            User ${setting.user}
        '')
        settings));
    in (pkgs.symlinkJoin {
      name = "ssh";
      paths = [pkgs.openssh];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/ssh --add-flags "-F ${configFile}"
      '';

      meta = {
        mainProgram = "ssh";
      };
    })) {};
  };
}
