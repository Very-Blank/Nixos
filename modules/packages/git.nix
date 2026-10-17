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

      configFile = pkgs.writeTextDir "git/config" config;
    in (pkgs.symlinkJoin {
      name = "git";
      paths = [pkgs.git];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/git --add-flags "-C ${configFile}"
      '';

      meta = {
        mainProgram = "git";
      };
    })) {};
  };
}
