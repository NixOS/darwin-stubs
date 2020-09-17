{ pkgs ? import <nixpkgs> {} }:
let
  drv = { stdenv, lib, makeWrapper, jq, yq, ruby, gnused }: stdenv.mkDerivation {
    name = "generate-all";
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
      cp *.json    $out/share

      makeWrapper $out/libexec/generate-all.sh $out/bin/generate-all \
        --prefix PATH : ${lib.makeBinPath [ jq yq gnused ]}

      ln -s $out/libexec/update-framework-names.sh $out/bin/update-framework-names
    '';
  };
in
  pkgs.callPackage drv {}
