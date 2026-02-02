{
  inputs.deploy = {
    url = ../.;
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, deploy }:
    flake-utils.lib.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        example = pkgs.runCommand "example" {} ''
          mkdir "$out"
          cp ${./index.html} "$out/index.html"
        '';

        serveExample = pkgs.writeShellScript "serve-example" ''
          ${pkgs.caddy}/bin/caddy file-server --browse \
            --listen :8000 \
            --root ${example}
        '';

        deployExample = pkgs.writeShellScript "deploy-example" ''
          ${deploy.packages.${system}.default}/bin/deploy "$@" ${example} gh-pages
        '';

        mkApp = { drv, description }: {
          type = "app";
          program = "${drv}";
          meta.description = description;
        };
      in
      {
        packages = {
          inherit example;
          default = example;
        };

        apps = {
          default = self.apps.${system}.example;

          example = mkApp {
            drv = serveExample;
            description = "The example website";
          };

          deploy = mkApp {
            drv = deployExample;
            description = "Deploy the example website";
          };
        };

        checks = {
          inherit example serveExample deployExample;
        };
      }
    );
}
