{
  inputs = {
    snapcore.url = "github:snapsettle/snapcore";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      treefmtConfig = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
    in
    {
      formatter.${system} = treefmtConfig.config.build.wrapper;

      nixosConfigurations.snowflake-ideapad = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.snapcore.nixosModules.default
        ];
      };
    };
}
