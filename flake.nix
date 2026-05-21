{
  description = "Oh My Pi - a coding agent with the IDE wired in";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      manifest = builtins.fromJSON (builtins.readFile ./versions.json);

      version = manifest.ompVersions.version;

      urls = manifest.ompVersions.urls;

      platformMap = {
        "x86_64-linux" = urls.linux.x86_64;
        "aarch64-linux" = urls.linux.aarch64;
        "x86_64-darwin" = urls.darwin.x86_64;
        "aarch64-darwin" = urls.darwin.aarch64;
      };
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          info =
            platformMap.${system} or (throw "Unsupported system: ${system}");

          oh-my-pi = pkgs.callPackage ./package.nix {
            inherit version;
            url = info.url;
            nixHash = info.hash;
          };
        in {
          default = oh-my-pi;
          inherit oh-my-pi;
        });

      overlays.default = final: prev:
        let
          sys = final.stdenv.hostPlatform.system;
          platformInfo = platformMap.${sys} or (throw
            "Unsupported system for oh-my-pi overlay: ${sys}");
        in {
          oh-my-pi = final.callPackage ./package.nix {
            inherit version;
            url = platformInfo.url;
            nixHash = platformInfo.hash;
          };
        };
    };
}