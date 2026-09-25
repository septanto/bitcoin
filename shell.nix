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
    export CPLUS_INCLUDE_PATH="${pkgs.lib.makeSearchPathOutput "dev" "include" deps}:''${CPLUS_INCLUDE_PATH:-}"
  '';
}
