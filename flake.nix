{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim = {
      url = "github:Very-Blank/nvim";
      flake = false;
    };
  };

  outputs = inputs: let
    inherit (inputs) home-manager nixpkgs niri nvim stylix;
    system = "x86_64-linux"; in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./configuration.nix
        niri.nixosModules.niri
      ];

      specialArgs = { inherit inputs system; };
    };

    homeConfigurations.blank = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [
        ./home.nix
        stylix.homeModules.stylix
        niri.homeModules.niri
      ];

      extraSpecialArgs = { inherit inputs system nvim; };
    };
  };
}
