{
  description = "Ancient";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    rec {
      packages = eachSystem (system:
        let
          legacyPackages = nixpkgs.legacyPackages.${system};
          ocamlPackages = legacyPackages.ocamlPackages;
        in rec
        {
          default = self.packages.${system}.ancient;

          ancient = ocamlPackages.buildDunePackage {
            pname = "ancient";
            version = "dev";
            duneVersion = "3";
            src = ./.;
          };
        });

      devShells = eachSystem (system:
        let
          legacyPackages = nixpkgs.legacyPackages.${system};
          ocamlPackages = legacyPackages.ocamlPackages;
          pkgs = packages.${system};
        in
        {
          default = legacyPackages.mkShell {
            packages = [
              legacyPackages.nixpkgs-fmt
              ocamlPackages.utop
              ocamlPackages.odoc
              ocamlPackages.ocaml-lsp
              ocamlPackages.patdiff
            ];

            inputsFrom = [
              pkgs.ancient
            ];
          };
        });
    };
}
