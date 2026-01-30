{
  description = "Ancient library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        git = pkgs.git;
        mkAncient = ocamlPackages:
          ocamlPackages.callPackage ./nix/ancient.nix {
            inherit git;
            src = ./.;
          };
        mkShell = ocamlPackages:
          pkgs.mkShell {
            packages = with ocamlPackages; ([
              utop
              odoc
              ocaml-lsp
              patdiff
              dune-release
              ocamlformat
            ] ++
            (pkgs.lib.optional (ocaml ? debug) ocaml.debug));

            inputsFrom = [
              (mkAncient ocamlPackages)
            ];
          };
        mkOcamlPackages =
          { ocamlVersion ? "ocamlPackages"
          , enableDebug ? false
          }: pkgs.ocaml-ng."ocamlPackages_${ocamlVersion}".overrideScope (final: super: {
            ocaml-src = with super.ocaml; pkgs.stdenv.mkDerivation {
              inherit src version patches;
              name = "ocaml-src";

              phases = [ "unpackPhase" "patchPhase" "installPhase" ];

              installPhase = ''
                cp -r . $out
              '';
            };

            ocaml = (super.ocaml.overrideAttrs (old: {
              dontStrip = enableDebug;
              separateDebugInfo = enableDebug;
              dontCheckForBrokenSymlinks = enableDebug;

              configureFlags = (old.configureFlags or [ ]) ++
                (pkgs.lib.optional enableDebug
                  "CFLAGS=-fdebug-prefix-map=/build/ocaml-${super.ocaml.version}=${final.ocaml-src}");
            })).override ({
              framePointerSupport = enableDebug;
              noNakedPointers = super.ocaml.version == "4.14";
            });
          });
      in
      rec {
        packages.ancient = mkAncient pkgs.ocamlPackages;
        formatter = pkgs.nixpkgs-fmt;

        devShells = {
          default = mkShell pkgs.ocamlPackages;
          ocaml4 = mkShell (mkOcamlPackages { ocamlVersion = "4_14"; enableDebug = true; });
          ocaml5 = mkShell (mkOcamlPackages { ocamlVersion = "5_3"; enableDebug = true; });
        };
      });
}
