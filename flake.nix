{
  description = "A Bash script for deploying static websites";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;

      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f:
        lib.genAttrs supportedSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          f system pkgs
        );
    in
    {
      packages = forAllSystems (_: pkgs:
        let
          deploy = self.lib.mkDeploy pkgs;
        in
        {
          inherit deploy;
          default = deploy;
        }
      );

      checks = forAllSystems (system: _:
        {
          deploy = self.packages.${system}.deploy;
        }
      );

      lib.mkDeploy = pkgs: pkgs.callPackage ./deploy.nix {};
    };
}
