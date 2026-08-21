#!/usr/bin/env bash
# Lay the vendor-snapshot shelf down as untracked files and install the
# wasm32 standard library into the active toolchain. Run by the CLOUD
# sandbox session before its first offline build (idempotent; safe to
# re-run after a shelf refresh).
#
# See docs/VENDORING.md.

set -euo pipefail

echo "==> fetching vendor-snapshot"
git fetch origin vendor-snapshot

echo "==> restoring vendor/ .cargo/ shelf/ (untracked, gitignored)"
git restore --source=origin/vendor-snapshot -- vendor/ .cargo/ shelf/ 2>/dev/null \
    || git checkout origin/vendor-snapshot -- vendor/ .cargo/ shelf/

sysroot="$(rustc --print sysroot)"
if [ -d "${sysroot}/lib/rustlib/wasm32-unknown-unknown" ]; then
    echo "==> wasm32-unknown-unknown std already installed in ${sysroot}"
else
    tarball="$(ls shelf/rust-std-*-wasm32-unknown-unknown.tar.xz | head -1)"
    rust_version="$(rustc --version | awk '{print $2}')"
    case "${tarball}" in
        *"${rust_version}"*) ;;
        *)
            echo "error: shelf tarball ${tarball} does not match rustc ${rust_version}." >&2
            echo "       Ask a networked session to refresh the shelf with" >&2
            echo "       SANDBOX_RUST_VERSION=${rust_version} (see docs/VENDORING.md)." >&2
            exit 1
            ;;
    esac
    echo "==> installing ${tarball} into ${sysroot}"
    tmp="$(mktemp -d)"
    tar -xJf "${tarball}" -C "${tmp}"
    compdir="$(find "${tmp}" -maxdepth 1 -type d -name 'rust-std-*' | head -1)"
    cp -r "${compdir}"/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown \
        "${sysroot}/lib/rustlib/"
    rm -rf "${tmp}"
fi

echo "==> hermetic build inputs ready:"
echo "    cargo tree --offline -e no-dev --depth 1   # sanity check"
echo "    cargo leptos build --release               # full build, no crates.io"
