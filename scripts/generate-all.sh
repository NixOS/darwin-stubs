#!/usr/bin/env bash

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

mkdir -p "$out"

@out@/libexec/stubify.sh -r -s "$sysroot" -o "$out" \
  /usr/lib/libSystem.B.dylib \
  /usr/lib/libcups.2.dylib \
  /usr/lib/libcupscgi.1.dylib \
  /usr/lib/libcupsimage.2.dylib \
  /usr/lib/libcupsmime.1.dylib \
  /usr/lib/libcupsppdc.1.dylib \
  /usr/lib/libXplugin.1.dylib \
  /usr/lib/libsandbox.1.dylib \
  /usr/lib/libcompression.dylib

@out@/libexec/frameworks-tbd.sh -s "$sysroot" -o "$out"

@out@/libexec/add-aliases.sh -s "$sysroot" -o "$out"
