# Vendored dependencies: how and why

*Adapted for the BayWorks site from kamiroh's scheme (decision 20 in
kamiroh's `ARCHITECTURE.md`; see `docs/VENDORING.md` in the
kamiroh-workshop-2 repo, adopted 2026-08-13). Same principles, one
extension for the WebAssembly toolchain this project needs.*

## The problem this solves

The cloud Cowork session's sandbox cannot reach crates.io or
static.rust-lang.org, so it needs dependency sources on disk to build and
verify (`cargo vendor` output). But committing `vendor/` to `master` is
expensive in a way that deleting it later cannot fix: **git history carries
every committed blob forever**, and merges carry history. Tree weight and
history weight are different things.

## The scheme

- **`master` never contains `vendor/`, `.cargo/`, or `shelf/`** — all are
  gitignored. Normal builds (Casey, local Claude Code sessions, Fly.io's
  remote builders) just use crates.io; nothing special to do.
- **The `vendor-snapshot` branch is an artifact shelf, not history.** It is
  an orphan branch containing only the build inputs the sandbox cannot
  download, matching the current `Cargo.lock`. It is force-pushed whenever
  dependencies change, merged into nothing, and ancestor of nothing. Its
  weight stays its own.
- **The shelf carries three things** (one more than kamiroh's, because this
  project compiles to WebAssembly as well as native):
  1. `vendor/` — `cargo vendor` output for every crate in `Cargo.lock`.
  2. `.cargo/config.toml` — the source-replacement stanza pointing cargo at
     `vendor/`.
  3. `shelf/rust-std-<version>-wasm32-unknown-unknown.tar.xz` — the wasm32
     standard library **for the sandbox's pinned rustc** (currently
     1.95.0), fetched from static.rust-lang.org by a networked session.
     This must match the sandbox's rustc *exactly* — not the local
     toolchain's version, which floats newer.

  (`cargo-leptos` itself and the matching `wasm-bindgen` CLI are *not* on
  the shelf: GitHub is reachable read-only from the sandbox, and both ship
  prebuilt binaries via GitHub releases.)

- **The cloud session lays the snapshot down as untracked files:**

  ```
  scripts/lay-down-snapshot.sh
  # which does, roughly:
  #   git fetch origin vendor-snapshot
  #   git restore --source=origin/vendor-snapshot -- vendor/ .cargo/ shelf/
  #   <unpack shelf wasm-std into $(rustc --print sysroot)/lib/rustlib/>
  cargo leptos build --release   # hermetic; crates.io never consulted
  ```

## When dependencies change (local Claude Code)

After a dep bump builds green locally, refresh the shelf:

```
scripts/refresh-vendor-snapshot.sh
```

which automates kamiroh's recipe, extended with the wasm-std download:
`cargo vendor`, fetch the pinned-version rust-std tarball, orphan-commit
`vendor/ .cargo/config.toml shelf/ Cargo.lock` to `vendor-snapshot`, and
force-push. Force-pushing here is fine and expected: the branch is a
single-writer artifact with no downstream ancestry.

## Toolchain floor

As in kamiroh: the sandbox's rustc is pinned by its environment (1.95.0 at
adoption) and is the **floor for language features**; local toolchains
float newer, and their newer clippy findings are a feature, not a
discrepancy. No `rust-toolchain.toml` — a newer pin would break the
sandbox outright, and pinning the older one would silence exactly the
signal we want. If the sandbox's pinned version ever changes, update the
`SANDBOX_RUST_VERSION` variable in `scripts/refresh-vendor-snapshot.sh`
and this note, then refresh the shelf.
