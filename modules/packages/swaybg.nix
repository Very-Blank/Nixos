{
  perSystem = {
    lib,
    pkgs,
    ...
  }: {
    packages.swaybg = lib.makeOverridable ({background ? ../../resources/wallpapers/nixos-logo-ascii.png}: let
    in (pkgs.symlinkJoin {
      name = "swaybg";
      paths = [pkgs.swaybg];
      buildInputs = [pkgs.makeWrapper];
      postBuild = let
        flags = [
          "--image ${background}"
        ];
      in
        lib.strings.concatStringsSep " " [
          "wrapProgram $out/bin/swaybg"
          "--add-flags \"${lib.strings.concatStringsSep " " flags}\""
        ];

      meta.mainProgram = "swaybg";
    })) {};
  };
}
