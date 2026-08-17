# Stage 1: Build environment
FROM rust:1.97.1-slim-trixie AS builder
WORKDIR /app
# Cache dependency builds by compiling a dummy entrypoint first
COPY Cargo.toml Cargo.lock* ./
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src
# Copy real source files and compile the final binary
COPY src ./src
RUN touch src/main.rs && cargo build --release
# Stage 2: Minimal runtime environment
# NOTE: same debian release (trixie) as the builder above, to avoid
# glibc-version mismatches between the compiled binary and the runtime.
FROM debian:trixie-slim AS runtime
# Only needed if your TUI makes HTTPS calls (API client, update checker, etc).
# Drop this whole block if it's fully offline.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*
# Run as a non-privileged user for security
RUN useradd -m -u 1000 appuser
USER appuser
WORKDIR /app
# Copy binary from builder stage — replace 'quantrs' if your Cargo.toml
# package/bin name differs
COPY --from=builder --chown=appuser:appuser /app/target/release/quantrs /app/quantrs
ENV RUST_LOG=info
# TUIs need a terminal, not a listening port — entrypoint is interactive
ENTRYPOINT ["/app/quantrs"]