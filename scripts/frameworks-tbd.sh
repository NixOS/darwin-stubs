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
frameworkNamesJSON=@out@/share/framework-names.json

# Derived from the linkFramework in nixpkgs
stubifyFramework() {
  local path="$1"
  local nested_path="$1"
  if [ "$path" == "JavaNativeFoundation.framework" ]; then
    local nested_path="JavaVM.framework/Versions/A/Frameworks/JavaNativeFoundation.framework"
  fi
  if [ "$path" == "JavaRuntimeSupport.framework" ]; then
    local nested_path="JavaVM.framework/Versions/A/Frameworks/JavaRuntimeSupport.framework"
  fi
  local name current
  name="$(basename "$path" .framework)"
  current="$(readlink "$sysroot/System/Library/Frameworks/$nested_path/Versions/Current")"
  if [ -z "$current" ]; then
    current=A
  fi

  $stubify -r -s "$sysroot" -o "$out" "/System/Library/Frameworks/$nested_path/Versions/$current/$name"

  pushd "$sysroot/System/Library/Frameworks/$nested_path/Versions/$current" >/dev/null
  local children
  children=$(echo Frameworks/*.framework)
  popd >/dev/null

  for child in $children; do
    childpath="$path/Versions/$current/$child"
    stubifyFramework "$childpath"
  done
}

jq -r '.[]' < "$frameworkNamesJSON" | while read -r name; do
  echo "Stubifying framework $name"
  if [ "$name" = Kernel ]; then
    echo "Skipping $name"
  else
    stubifyFramework "${name}.framework"
  fi
done
