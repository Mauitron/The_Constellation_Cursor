{
  description = "The Constellation Cursor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let pkgs = mkPkgs system;
        in {
          the-constellation-cursor = pkgs.callPackage ./nix/default.nix {inherit self;};
          default = self.packages.${system}.the-constellation-cursor;
        }
      );

      devShells = forAllSystems (system:
        let pkgs = mkPkgs system;
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              rustc
              cargo
              rust-analyzer
              libdrm
            ];
          };
        }
      );

  homeManagerModules.default = import ./nix/hm-module.nix;
 };
}
