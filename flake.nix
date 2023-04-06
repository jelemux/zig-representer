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

      # Our supported systems are the same supported systems as the Zig binaries
      systems = builtins.attrNames inputs.zig.packages;

      pname = "zig-representer";
      version = "0.0.0";

      zigVersion = "0.10.1";
      z = pkgs.zigpkgs.${zigVersion};

      zig_representer = pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = ./.;
        nativeBuildInputs = with pkgs; [ z ];
        buildInputs = with pkgs; [ ];
        dontConfigure = true;

        preBuild = ''
          export HOME=$TMPDIR
        '';

        installPhase = ''
          runHook preInstall
          zig build -Drelease-safe --prefix $out install
          runHook postInstall
        '';

        installFlags = ["DESTDIR=$(out)"];

        meta = with pkgs.lib; {
          description = "An Exercism representer for the Zig programming language";
          license = licenses.mit;
          platforms = platforms.linux;
          maintainers = with maintainers; [ jelemux ];
        };
      };

    in rec {
      packages = {
        zig_representer = zig_representer;
        default = zig_representer;
      };

      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ ];
        buildInputs = with pkgs; [ z ];
      };
    });
}
