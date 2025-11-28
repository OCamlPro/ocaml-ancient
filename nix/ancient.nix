{ src
, lib
, buildDunePackage
, git
}:

buildDunePackage {
  pname = "ancient";
  inherit src;
  version = "dev";

  nativeBuildInputs = [ git ];

  meta = {
    description = "Ancient library";
    homepage = "https://github.com/OCamlPro/ocaml-ancient";
    license = lib.licenses.gpl2;
  };
}
