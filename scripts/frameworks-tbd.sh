#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

out=$PWD/frameworks-tbd
sysroot=/

log() {
  echo "$@" >&2
}

while getopts "o:s:" opt; do
  case $opt in
    o) # output-dir
      out=$OPTARG
      ;;
    s) # sysroot
      sysroot=$OPTARG
      ;;
    \?)
      log "invalid option specified"
      exit 1
      ;;
  esac
done

stubify=@out@/libexec/stubify.sh

stubifyFramework() {
  local path="$1"
  local name

  name="$(basename "$path" .framework)"

  if [ ! -e "${sysroot}$path/$name" ]; then
    log "Framework '$name' does not have a library to stub"
    return 0
  fi

  lib_relpath=$(realpath --relative-to="$sysroot" "${sysroot}$path/$name")

  $stubify -r -s "$sysroot" -o "$out" "/$lib_relpath"
}

while read -r path; do
  path="/${path}"
  name=$(basename "$path" .framework)

  log "Stubifying framework $name at $path"
  stubifyFramework "$path"
done < <(cd "$sysroot" && find System/Library -type d -name '*.framework')
