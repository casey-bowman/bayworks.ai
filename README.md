# BayWorks website

The website of BayWorks (a dba of Pacific Bay LLC), built with [Leptos](https://leptos.dev)
(SSR + hydration on Axum) and deployed to [Fly.io](https://fly.io).

## Stack

- **Leptos 0.8** — full-stack Rust web framework (server-side rendering, then hydration to WASM in the browser)
- **Axum** — the HTTP server Leptos integrates with
- **cargo-leptos** — build tool that compiles both the server binary and the WASM client bundle
- **Fly.io** — hosting, via the included multi-stage `Dockerfile`

## Local development

Prereqs (one-time):

```sh
rustup target add wasm32-unknown-unknown
cargo install cargo-leptos --locked
```

Run the dev server with hot reload:

```sh
cargo leptos watch
```

Then open http://localhost:8080.

## Deploying to Fly.io

One-time setup:

```sh
# install flyctl if you don't have it
curl -L https://fly.io/install.sh | sh

fly auth login          # or `fly auth signup` if you don't have an account

# create the app (run from this directory; keeps the name in fly.toml)
fly launch --no-deploy --copy-config
```

Deploy (builds the Docker image on Fly's remote builders — no local Docker needed):

```sh
fly deploy
```

The app serves on port 8080 internally; Fly terminates TLS and serves
https://bayworks.fly.dev (until a custom domain is added).

### Custom domain

```sh
fly certs add www.example.com
```

Then add the DNS records `fly certs show` tells you about.

## Project layout

```
src/main.rs     # server entry point (Axum + Leptos SSR)
src/lib.rs      # WASM hydration entry point
src/app.rs      # all components: shell, layout, pages
style/main.css  # single stylesheet
public/         # static assets (logos, favicon)
```

## Workflow and vendoring

This project borrows kamiroh's development workflow: the cloud Cowork
session designs, writes, and verifies; local Claude Code sessions handle
everything that needs push access or open egress (pushes, dependency bumps,
refreshing the artifact shelf); the human merges and pushes. The cloud
session works only under `cowork/*` branches — `master` advances by
deliberate merges. Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
`fix:`, `chore:`, `docs:`, `build:`, …), adopted 2026-08-23; earlier
commits predate the convention and stay as they are.

The cloud sandbox cannot reach crates.io or static.rust-lang.org, so
hermetic builds use a `vendor-snapshot` orphan branch (an artifact shelf
carrying `vendor/`, `.cargo/config.toml`, and the wasm32 standard library
for the sandbox's pinned rustc). See `docs/VENDORING.md`;
`scripts/refresh-vendor-snapshot.sh` (networked side) and
`scripts/lay-down-snapshot.sh` (cloud side) automate both halves.
