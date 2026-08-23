#!/usr/bin/env bash
# Refresh the vendor-snapshot artifact shelf (run by a NETWORKED session —
# local Claude Code or Casey — never by the cloud sandbox).
#
# See docs/VENDORING.md. The shelf is an orphan branch carrying exactly:
#   vendor/  .cargo/config.toml  shelf/rust-std-*-wasm32-unknown-unknown.tar.xz  Cargo.lock
# matching the current Cargo.lock. Force-push is expected: single-writer
# artifact, no downstream ancestry.

set -euo pipefail

# The cloud sandbox's pinned rustc — the wasm std on the shelf must match it
# EXACTLY (not the local toolchain, which floats newer).
SANDBOX_RUST_VERSION="1.95.0"

branch="$(git rev-parse --abbrev-ref HEAD)"
src_sha="$(git rev-parse --short HEAD)"

if [ "$branch" = "vendor-snapshot" ]; then
    echo "error: run this from the working branch whose Cargo.lock is current, not vendor-snapshot" >&2
    exit 1
fi

# Never strand the repo on the orphan branch: on any failure, force-return
# to the working branch. -f is safe throughout: this script never modifies
# source files, so anything checkout would overwrite is byte-identical to
# the branch's committed content.
restore_branch() {
    git checkout -qf "${branch}" 2>/dev/null || true
}
trap restore_branch ERR

echo "==> vendoring crates for Cargo.lock @ ${src_sha} (branch ${branch})"
cargo vendor vendor

echo "==> ensuring .cargo/config.toml source replacement"
mkdir -p .cargo
cat > .cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

std_tarball="rust-std-${SANDBOX_RUST_VERSION}-wasm32-unknown-unknown.tar.xz"
mkdir -p shelf
if [ ! -f "shelf/${std_tarball}" ]; then
    echo "==> fetching ${std_tarball} for the sandbox toolchain"
    curl --proto '=https' --tlsv1.2 -fL -o "shelf/${std_tarball}" \
        "https://static.rust-lang.org/dist/${std_tarball}"
else
    echo "==> shelf/${std_tarball} already present, keeping it"
fi

echo "==> committing orphan vendor-snapshot"
git checkout --orphan vendor-snapshot
git rm -rfq --cached .
git add -f vendor .cargo/config.toml shelf Cargo.lock
git commit -m "vendor snapshot for Cargo.lock @ ${src_sha}"

echo "==> force-pushing vendor-snapshot"
git push -f origin vendor-snapshot

# -f is required, not cosmetic: the orphan commit made every source file
# untracked (git rm --cached), and a plain checkout refuses to overwrite
# untracked files. They are byte-identical to the branch's content.
trap - ERR
git checkout -f "${branch}"
echo "==> done; back on ${branch}"
echo "    (vendor/, .cargo/, and shelf/ were tracked on vendor-snapshot, so"
echo "     switching back removed them from the working tree. That's fine:"
echo "     local builds use crates.io, and the cloud session restores them"
echo "     from the pushed shelf via scripts/lay-down-snapshot.sh)"
