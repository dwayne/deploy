{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-utils-src = { url = "github:dwayne/nix-utils"; flake = false; };
    flake-deploy = {
      url = "../.";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-utils-src.follows = "nix-utils-src";
      };
    };
  };

  outputs = { self, nixpkgs, nix-utils-src, flake-deploy }:
    let
      lib = nixpkgs.lib;
      nixUtils = import nix-utils-src lib;
    in
    nixUtils.eachDefaultSystem(system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        buildExample = { noJekyll ? false }:
          pkgs.runCommand "example" {} ''
            mkdir "$out"
            cp ${./index.html} "$out/index.html"
            ${pkgs.lib.optionalString noJekyll ''
              touch "$out/.nojekyll"
            ''}
          '';

        serveExample = { src, port ? 8000 }: pkgs.writeShellApplication {
          name = "serve-example";
          runtimeInputs = [ pkgs.caddy ];
          text = ''
            exec caddy file-server --browse --listen :${builtins.toString port} --root ${src}
          '';
        };

        deployExample = { src, branch ? "gh-pages" }: pkgs.writeShellApplication {
          name = "deploy-example";
          runtimeInputs = [ flake-deploy.packages.${system}.deploy ];
          text = ''
            exec deploy "$@" "${src}" ${branch}
          '';
        };

        exampleDev = buildExample {};
        exampleProd = buildExample { noJekyll = true; };

        serveDev = serveExample { src = exampleDev; };
        serveProd = serveExample { src = exampleProd; port = 8001; };

        deployProd = deployExample { src = exampleProd; };
      in
      {
        packages = {
          inherit
            exampleDev exampleProd
            serveDev serveProd
            deployProd;

          default = exampleDev;
        };

        apps = {
          default = self.apps.${system}.serveDev;

          serveDev = {
            type = "app";
            program = pkgs.lib.getExe serveDev;
            meta.description = "Serve the development version of the example website";
          };

          serveProd = {
            type = "app";
            program = pkgs.lib.getExe serveProd;
            meta.description = "Serve the production version of the example website";
          };

          deployProd = {
            type = "app";
            program = pkgs.lib.getExe deployProd;
            meta.description = "Deploy the production version of the example website";
          };
        };

        checks = {
          inherit
            exampleDev exampleProd
            serveDev serveProd
            deployProd;
        };
      }
    );
}
