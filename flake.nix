{
  description = "My NixOS stuffs";

  inputs = let
    follows = url: {
      url = url;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  in {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    # NOTE: These should help make things more organized.
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    sops-nix = follows "github:Mic92/sops-nix";

    preservation.url = "github:nix-community/preservation";

    disko = follows "github:nix-community/disko";

    hjem = follows "https://github.com/feel-co/hjem";

    colors.url = "github:Very-Blank/colors";

    sefirah = follows "github:Very-Blank/Sefirah";

    quickshell = follows "github:Very-Blank/QuickShellBar";

    firefox-addons = follows "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };

    niri.url = "git+https://codeberg.org/BANanaD3V/niri-nix";

    nixnvim = follows "github:Very-Blank/NixNvim";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;
    }
    (inputs.import-tree ./modules);
}
