{
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          deploy = pkgs.callPackage ./deploy.nix {};
          default = self.packages.${system}.deploy;
        };
      }
    );
}
