{ pkgs ? import <nixpkgs> {} }:
let
  drv = { stdenv, lib, makeWrapper, jq, yq, ruby, gnused, coreutils }: stdenv.mkDerivation {
    name = "darwin-stubs-tools";
    src = lib.sourceFilesBySuffices ./. [ ".sh" ".rb" ".json" ];

    nativeBuildInputs = [ makeWrapper ];
    buildInputs = [ ruby ];

    buildPhase = ''
      for script in *.sh; do
        substituteInPlace "$script" --subst-var out
      done
    '';

    installPhase = ''
      mkdir -p $out/{libexec,share}
      cp *.rb *.sh $out/libexec

      makeWrapper $out/libexec/generate-all.sh $out/bin/generate-all \
        --prefix PATH : ${lib.makeBinPath [ jq yq gnused coreutils ]}
      makeWrapper $out/libexec/update-framework-names.sh \
        $out/bin/update-framework-names \
        --prefix PATH : ${lib.makeBinPath [ coreutils ]}
    '';
  };
in
  pkgs.callPackage drv {}
