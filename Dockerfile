# syntax=docker/dockerfile:1.21

ARG BUILD_DIR=/build

# Check https://github.com/be5invis/Iosevka/releases for font version
ARG IOSEVKA_VERSION=34.2.1

################################################################

# Fat builder: all deps, download source, bun install
FROM oven/bun:debian AS builder

ARG BUILD_DIR
ARG IOSEVKA_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN <<-EOF
    set -e
    apt-get update -yqq
    apt-get install --no-install-recommends -yqq \
        build-essential \
        ca-certificates \
        curl \
        fontforge \
        python3-fontforge \
        ttfautohint
EOF

RUN <<-EOF
    set -ex
    curl -sSL https://github.com/be5invis/Iosevka/archive/v${IOSEVKA_VERSION}.tar.gz | tar xz -C /
    mkdir -p ${BUILD_DIR}
    mv /Iosevka-${IOSEVKA_VERSION} ${BUILD_DIR}/iosevka
EOF

WORKDIR ${BUILD_DIR}/iosevka
RUN bun install

################################################################

# Slim runtime image
FROM debian:trixie-slim

ARG BUILD_DIR

ENV DEBIAN_FRONTEND=noninteractive

RUN <<-EOF
    set -e
    apt-get update -yqq
    apt-get install --no-install-recommends -yqq \
        python3-fontforge \
        ttfautohint
    rm -rf /var/lib/apt/lists/*
EOF

COPY --from=builder /usr/local/bin/bun /usr/local/bin/bun
COPY --from=builder ${BUILD_DIR}/iosevka ${BUILD_DIR}/iosevka

WORKDIR ${BUILD_DIR}/src/glyphs
COPY --link nerd/glyphs .

WORKDIR ${BUILD_DIR}
COPY --link nerd/font-patcher .
COPY --link ./src/docker_run.py .
RUN chmod +x docker_run.py

WORKDIR ${BUILD_DIR}

ENTRYPOINT ["/bin/bash"]
