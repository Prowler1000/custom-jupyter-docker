ARG BASE=quay.io/jupyter/base-notebook:2026-11-23

FROM ${BASE} as builder
USER root
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    curl \
    ca-certificates

ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path \ 
    --profile minimal --default-toolchain stable \
    && cargo install --locked evcxr_jupyter --root /opt/evcxr

FROM ${BASE}
USER root
RUN apt update && apt install -y --no-install-recommends \
    gcc libc6-dev curl ca-certificates \
    && apt clean \

ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:/opt/evcxr/bin:$PATH

RUN mkdir -p /opt/rustup /opt/cargo && chown -R ${NB_UID}:${NB_GID} /opt/rustup /opt/cargo

USER ${NB_UID}
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && ~/.cargo/bin/rustup component add rust-src \
    && fix-permissions /opt/rustup /opt/cargo

# Copy only the compiled binaries from the builder stage
COPY --from=builder /opt/evcxr/bin/evcxr_jupyter /opt/evcxr/bin/evcxr_jupyter
RUN evxcr_jupyter --install
RUN pip install --no-cache-dir \
    numpy \
    sympy \
    matplotlib \
    pint