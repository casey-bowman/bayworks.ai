# ---- Build stage -----------------------------------------------------------
FROM rust:1-bookworm AS builder

# wasm target for the client bundle
RUN rustup target add wasm32-unknown-unknown

# cargo-leptos (prebuilt binary installer; falls back to cargo install if needed)
RUN curl --proto '=https' --tlsv1.2 -LsSf \
        https://github.com/leptos-rs/cargo-leptos/releases/latest/download/cargo-leptos-installer.sh | sh \
    || cargo install cargo-leptos --locked

WORKDIR /app
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
