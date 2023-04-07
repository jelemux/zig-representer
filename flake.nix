{
  description = "An Exercism representer for the Zig programming language";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;
    zig.url     = github:mitchellh/zig-overlay;
    utils.url   = github:numtide/flake-utils;

    # Used for shell.nix
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = {self, nixpkgs, zig, utils, ...} @ inputs: with utils.lib;
    eachSystem (builtins.filter (sys: !(builtins.elem sys [system.x86_64-darwin system.aarch64-darwin])) defaultSystems) (system: let

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            zigpkgs = inputs.zig.packages.${prev.system};
            # zig = inputs.zig.packages.${zigVersion}.${prev.system};
          })
        ];
      };

      zigVersion = "0.10.1";
      z = pkgs.zigpkgs.${zigVersion};

    in rec {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ ];
        buildInputs = with pkgs; [ z ];
      };
    });
}
