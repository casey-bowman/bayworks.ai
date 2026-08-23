# ---- Chef base: toolchain + build tools (cached until rust image changes) --
FROM rust:1-bookworm AS chef

RUN cargo install cargo-chef --locked
RUN rustup target add wasm32-unknown-unknown
RUN curl --proto '=https' --tlsv1.2 -LsSf \
        https://github.com/leptos-rs/cargo-leptos/releases/latest/download/cargo-leptos-installer.sh | sh \
    || cargo install cargo-leptos --locked
WORKDIR /app

# ---- Planner: distill the dependency recipe from the manifests ------------
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ---- Builder: cook dependencies (cached until Cargo.toml/lock change), ----
# ---- then build the real crate ------------------------------------------
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json

# Cook both halves the way cargo-leptos will build them, so the dependency
# artifacts are already in target/ when the real build runs:
#   server: --features ssr, release profile, host target
#   client: --features hydrate, wasm-release profile, wasm32 target
RUN cargo chef cook --release --no-default-features --features ssr \
        --recipe-path recipe.json
RUN cargo chef cook --profile wasm-release --no-default-features --features hydrate \
        --target wasm32-unknown-unknown --recipe-path recipe.json

COPY . .
RUN cargo leptos build --release -vv

# ---- Runtime stage ---------------------------------------------------------
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/bayworks /app/bayworks
COPY --from=builder /app/target/site /app/site

ENV RUST_LOG=info \
    LEPTOS_SITE_ADDR=0.0.0.0:8080 \
    LEPTOS_SITE_ROOT=/app/site

EXPOSE 8080
CMD ["/app/bayworks"]
