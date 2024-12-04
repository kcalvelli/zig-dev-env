{
  description = "Zig flake";

  # Flake inputs
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
    
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls-overlay.url = "github:zigtools/zls";
  };

  outputs = { self, zig-overlay, zls-overlay, flake-schemas, nixpkgs }@ inputs:
    let
      supportedSystems = [ "x86_64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { 
          inherit system;
          overlays = [
            inputs.zig-overlay.overlays.default
            (final: prev: {
              zlspkgs = inputs.zls-overlay.packages.${system}.default;
            })
          ];
        };
      });
    in {
      # Schemas tell Nix about the structure of your flake's outputs
      schemas = flake-schemas.schemas;

      # Zig Development Environment using master 
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zigpkgs.master
            zlspkgs
            curl
            git
            jq
            wget
            nixpkgs-fmt
          ];

          # A hook run every time you enter the environment
          shellHook = ''
            echo "Loading zig ..."
          '';
        };
      });
    };
}
