{
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = import nixpkgs { inherit system; };

        deploy = pkgs.callPackage ./deploy.nix {};
      in
      {
        packages = {
          inherit deploy;
          default = deploy;
        };

        checks = {
          inherit deploy;
        };
      }
    );
}
