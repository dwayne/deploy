# Usage

## Build

```bash
nix build .#exampleDev -L # or nix build -L
nix build .#exampleProd -L
nix build .#serveDev -L
nix build .#serveProd -L
nix build .#deployProd -L
```

## Serve

```bash
nix run .#serveDev # or nix run
# port=8000

nix run .#serveProd
# port=8001
```

## Deploy

```bash
nix run .#deployProd
```

## Test

```bash
nix flake check -L
```
