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
            packages = with ocamlPackages; [
              utop
              odoc
              ocaml-lsp
              patdiff
              dune-release
            ];

            inputsFrom = [
              (mkAncient ocamlPackages)
            ];
          };
      in
      rec {
        packages.ancient = mkAncient pkgs.ocamlPackages;
        formatter = pkgs.nixpkgs-fmt;

        devShells = {
          default = mkShell pkgs.ocamlPackages;

          ocaml4 =
            let
              ocamlPackages4 = pkgs.ocaml-ng.ocamlPackages_4_14.overrideScope (final: super: {
                ocaml = super.ocaml.override { noNakedPointers = true; };
              });
            in
            mkShell ocamlPackages4;
        };
      });
}
