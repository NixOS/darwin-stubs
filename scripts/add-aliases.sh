#!/usr/bin/env bash

# Scan all symlinks in $sysroot that refer to things we have stubs
# for, and create equivalent stub symlinks.

set -euo pipefail

out=$PWD/stubs

log() {
  echo "$@" >&2
}

while getopts "o:s:" opt; do
  case $opt in
    o) # output
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

stub_name() {
  echo "${1%.dylib}.tbd"
}

out=$(realpath "$out")
cd "$sysroot"

while read -r symlink; do
  log "Considering alias: '$symlink'"
  final_path=$(realpath --relative-to="$sysroot" "$symlink" || true)
  log -e "\tFinal path: '$final_path'"
  if [[ "$final_path" == "" || "$final_path" == ../* ]]; then
    log -e "\ttarget '$final_path' is invalid or outside of sysroot; ignoring"
    continue
  fi

  expected_stub=$out/$(stub_name "$final_path")
  if [ ! -e "$expected_stub" ]; then
    log -e "\texpected stub file '$expected_stub' not in output; ignoring"
    continue
  fi

  source=$out/$(stub_name "$symlink")
  target=$(stub_name "$(readlink "$symlink")")
  ln -sv "$target" "$source"
done < <(find "usr/lib" -type l)
