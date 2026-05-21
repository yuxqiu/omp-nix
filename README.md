# omp-nix

Nix flake for [Oh My Pi](https://github.com/can1357/oh-my-pi) — a coding agent with the IDE wired in.

Automatically tracks the latest release and updates binaries daily via CI.

## Usage

### Run directly

```bash
nix run github:yuxqiu/omp-nix
```

### Install into a profile

```bash
nix profile install github:yuxqiu/omp-nix
```

### Add to your own flake

```nix
{
  inputs.omp-nix.url = "github:yuxqiu/omp-nix";

  outputs = { nixpkgs, omp-nix, ... }@inputs: {
    # Use inputs.omp-nix.packages.${system}.default
  };
}
```

### Use as an overlay

```nix
{
  inputs.omp-nix.url = "github:yuxqiu/omp-nix";

  outputs = { nixpkgs, omp-nix, ... }@inputs: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ omp-nix.overlays.default ];
    };
  in {
    # pkgs.oh-my-pi is now available
  };
}
```

## NixOS compatibility

On Linux/NixOS, the downloaded binary is a Bun-compiled standalone executable that requires a dynamic linker wrapper. The flake handles this automatically by:

- Wrapping the binary with the Nix-provided `ld-linux` interpreter
- Setting `BUN_SELF_EXE` so Bun correctly resolves its embedded bytecode (see [oven-sh/bun#26752](https://github.com/oven-sh/bun/issues/26752))

On macOS, the binary works directly without a wrapper.

## Supported platforms

| Platform | Arch |
|----------|------|
| Linux    | x86_64, aarch64 |
| macOS    | x86_64, aarch64 |

## Auto-updates

A GitHub Actions workflow runs daily (and on manual trigger) to check for new releases. When a new version is found, it:

1. Fetches the latest release assets
2. Computes Nix hashes for each platform
3. Updates `versions.json`
4. Verifies the build succeeds
5. Commits the update and creates a GitHub Release

## Manual update

```bash
./scripts/update.sh
``