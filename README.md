# darwin-stubs

Text API (TAPI) files to support a pure build environment on macOS in
nixpkgs.

## Generation

    nix run -f scripts -c generate-all -s "$MACOS_10_12_SYSROOT" -o stubs/10.12

## Framework Names

These are derived from nixpkgs and stored in this repository for
consistency. To update:

    nix run -f scripts -c update-framework-names -o scripts/framework-names.json

## Re-exports and absolute paths

Some libraries frameworks contain a `re-exports` section that exposes
other libraries and frameworks by their absolute path. When generating
stubs, the scripts recuse through all `re-exports` entries.

In regular usage of detached tbd stubs, the linker will use the
`syslibroot` option to find libraries by their absolute
names[1][]. Nixpkgs does not have a single SDK to pass as the
`syslibroot`, but passes individual frameworks as required. To support
re-exports, the absolute paths are rewritten to the corresponding nix
store paths of the stubs.

For libSystem the re-exports are trivial enough that it's sufficient
to replace `/usr/lib/libsystem` with `$out/lib/libsystem`, which is
part of the libSystem definition in nixpkgs.

For frameworks there are links between many frameworks. This is
handled by a two step process. In the definition of these stubs, the
framework path of re-exports is rewritten from
`/System/Library/SomeFramework.framework` to
`@SomeFramework@/Library/SomeFramework.framework`. When assembling the
frameworks for `darwin.apple_sdk.frameworks`, nixpkgs uses
`substituteInPlace --subst-var-by SomeFramework /nix/store/...` to
provide dependencies. To ensure correctness, the builder checks that
each re-exported file actually exists.

[1]: https://reviews.llvm.org/D4409#56025
