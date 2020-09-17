#!/usr/bin/env bash

set -euo pipefail

# Generate TBD files for libsystem by inspecting the specified sysroot
# - Requires Xcode installed to generate (TODO: use libtapi instead)

log() {
  echo "$@" >&2
}

tapi() {
  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi "$@"
}

out=$PWD/tbd
sysroot=/
recur=
append=

while getopts "o:s:ra" opt; do
  case $opt in
    o) # output-dir
      out=$OPTARG
      ;;
    s) # sysroot
      sysroot=$OPTARG
      ;;
    r) # recurse into re-exported libraries
      recur=1
      ;;
    a) # append re-exports
      append=1
      ;;
    \?)
      log "invalid option specified"
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

mkdir -p "$out"

result_name() {
  local lib=$1
  local result=$out$lib
  result=${result%.dylib}.tbd
  echo "$result"
}

export_library() {
  local result

  local lib=$1
  result=$(result_name "$lib")
  local file=$sysroot/$lib

  log -e "tapi stubify\n\tlib: $lib\n\tfile: $file\n\tto: $result"
  mkdir -p "$(dirname "$result")"

  tapi stubify  --filetype=tbd-v2 -isysroot "$sysroot" "$file" -o "$result"

  local reexports
  mapfile -t reexports < <(yq -r '.exports[]."re-exports" | if . == null then [] else . end | .[]' "$result")

  if [ "$recur" ] && [ "${#reexports[@]}" -gt 0 ]; then
    log "Discovered ${#reexports[@]} re-exported libraries"

    for exported_lib in "${reexports[@]}"; do
      log -e "\t -${exported_lib}"
    done

    for exported_lib in "${reexports[@]}"; do
      log "Processing re-exported library: $exported_lib"
      export_library "$exported_lib"

      if [ "$append" ]; then
        reexported_result=$(result_name "$exported_lib")
        log -e "Appending re-exported library\n\tfrom: $reexported_result\n\tto: $result"
        cat "$reexported_result" >> "$result"
      fi
    done

    if [ "$append" ]; then
      # Fixup manually combined yaml documents: remove end of document
      # markers, and recreate the final marker.
      sed -i"" -e '/^\.\.\.$/d' "$result"
      echo '...' >> "$result"
    fi
  fi
}

if [ "$#" -eq 0 ]; then
  log "No libraries specified, nothing to do!"
fi

for library in "$@"; do
  export_library "$library"
done
