{ pkgs ? import <nixpkgs> {} }:
let
  # External dependencies whose headers are needed by Bitcoin Core.
  deps = with pkgs; [
    boost
    libevent
    sqlite
    zeromq
    openssl
    zlib
    python3
    capnproto
  ];
in
pkgs.mkShell {
  packages = deps ++ (with pkgs; [
    stdenv.cc
    cmake
    pkg-config
  ]);

  # Nix exposes dependency headers to the compiler wrapper via
  # NIX_CFLAGS_COMPILE, which clangd does not read. Mirror them into
  # CPLUS_INCLUDE_PATH (built from the package set above, so the store paths
  # update automatically) so any clang-based tool started from this shell can
  # find <boost/...>, <event2/...>, etc. See .clangd for details.
  shellHook = ''
    dep_includes="${pkgs.lib.makeSearchPathOutput "dev" "include" deps}"

    # Strip empty components from any pre-existing value before prepending.
    # An empty entry (the trailing ':' produced by blindly appending
    # ''${CPLUS_INCLUDE_PATH:-} when it is unset) makes GCC treat the current
    # working directory as an include directory. GCC then de-duplicates it
    # against the matching -I flag CMake passes, and the surviving cwd entry
    # sits *after* the dependency dirs above. Builds run with cwd
    # build/src/ipc, so capnproto's own capnp/rpc.capnp.h is found before the
    # generated build/src/ipc/capnp/rpc.capnp.h, and
    # `cmake --build build` fails while compiling the IPC capnp proxies with
    # "'ipc' does not name a type". See .clangd for why this variable exists.
    prev="$(tr ':' '\n' <<< "''${CPLUS_INCLUDE_PATH:-}" | sed '/^$/d' | paste -sd: -)"
    if [ -n "$prev" ]; then
      export CPLUS_INCLUDE_PATH="$dep_includes:$prev"
    else
      export CPLUS_INCLUDE_PATH="$dep_includes"
    fi
    unset dep_includes prev
  '';
}
