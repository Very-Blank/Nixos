{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.git = lib.makeOverridable ({
      editor ? "nvim",
      defaultBranch ? "main",
      user ? null,
      extraConfig ? null,
    }: let
      config = lib.strings.concatStringsSep "\n" [
        ''
          [core]
          	editor = "${editor}"

          [init]
          	defaultBranch = "${defaultBranch}"

          [pull]
          	rebase = false
        ''
        (
          lib.optionalString (user != null)
          ''
            [user]
            	email = "${user.email}"
            	name = "${user.name}"
          ''
        )
        (lib.optionalString (extraConfig != null) extraConfig)
      ];

      configFile = pkgs.writeText "config" config;
    in (pkgs.symlinkJoin {
      name = "git";
      paths = [pkgs.git];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/git --set GIT_CONFIG_GLOBAL ${configFile}
      '';

      meta = {
        mainProgram = "git";
      };
    })) {};
  };
}
