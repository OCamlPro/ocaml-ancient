{
  description = "Ancient";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        ocamlPackages4 = pkgs.ocaml-ng.ocamlPackages_4_14.overrideScope (self: super: {
          ocaml = super.ocaml.override { noNakedPointers = true; };
        });

        ocamlPackages5 = pkgs.ocaml-ng.ocamlPackages_5_1;

        buildAncient = ocamlPackages: ocamlPackages.buildDunePackage {
          pname = "ancient";
          version = "dev";

          duneVersion = "3";
          src = ./.;

          nativeBuildInputs = [ pkgs.git ];
        };

        devShellFor = ocamlPackages: ancient: pkgs.mkShell {
          packages = with ocamlPackages; [
            utop
            odoc
            ocaml-lsp
            patdiff
            dune-release
          ];

          inputsFrom = [ ancient ];
        };
      in
      {
        packages = {
          default = buildAncient ocamlPackages5;
          ocaml4 = buildAncient ocamlPackages4;
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells = {
          default = devShellFor ocamlPackages5 self.packages.${system}.default;
          ocaml4 = devShellFor ocamlPackages4 self.packages.${system}.ocaml4;
        };
      });
}
