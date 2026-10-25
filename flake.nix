{
  description = "A Bash script to deploy static websites";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-utils-src = { url = "github:dwayne/nix-utils"; flake = false; };
  };

  outputs = { self, nixpkgs, nix-utils-src }:
    let
      lib = nixpkgs.lib;
      nixUtils = import nix-utils-src lib;
    in
    nixUtils.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        deploy = pkgs.callPackage ./deploy.nix {};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "deploy";
          packages = [ deploy ];
        };

        packages = {
          inherit deploy;
          default = deploy;
        };

        apps = {
          default = self.apps.${system}.deploy;
          deploy = {
            type = "app";
            program = lib.getExe deploy;
            meta.description = "Deploy static websites";
          };
        };

        checks = { inherit deploy; };
      }
    ) // {
      overlays.default = final: prev: {
        deploy = final.callPackage ./deploy.nix {};
      };
    };
}
