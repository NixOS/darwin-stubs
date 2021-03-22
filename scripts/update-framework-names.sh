#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

log() {
  echo "$@" >&2
}

out=$PWD

while getopts "o:" opt; do
  case $opt in
    o) # output-file
      out=$OPTARG
      ;;
    \?)
      log "invalid option specified"
      exit 1
      ;;
  esac
done

install -Dm a=r,u+w "$(nix-build --no-out-link --expr '
  let
    pkgs = import <nixpkgs> {};
  in
  pkgs.writeText "frameworks.json" (builtins.toJSON (builtins.attrNames pkgs.darwin.apple_sdk.frameworks))
')" "$out"
