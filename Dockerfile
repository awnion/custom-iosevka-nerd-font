# syntax=docker/dockerfile:1.21

ARG BUILD_DIR=/build
ARG FONT_NAME=afio

# Check https://github.com/be5invis/Iosevka/releases for font version
ARG FONT_VERSION=34.1.0

################################################################

FROM oven/bun:debian AS base_builder

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN \
    --mount=type=cache,id=apt-${TARGETARCH},target=/var/cache/apt \
    --mount=type=cache,id=apt-${TARGETARCH},target=/var/lib/apt \
    <<-EOF
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


FROM base_builder AS iosevka_src

ARG FONT_VERSION

WORKDIR /
RUN <<-EOF
    set -ex
    curl -sSL https://github.com/be5invis/Iosevka/archive/v${FONT_VERSION}.tar.gz | tar xvz
    mv /Iosevka-${FONT_VERSION} /iosevka
EOF


FROM base_builder AS builder_iosevka

ARG TARGETARCH
ARG FONT_NAME
ARG BUILD_DIR

WORKDIR ${BUILD_DIR}/iosevka
COPY --link private-build-plans.toml .
COPY --from=iosevka_src /iosevka .

RUN --mount=type=cache,id=node-${TARGETARCH},target=${BUILD_DIR}/iosevka/node_modules \
    <<-EOF
    set -ex
    bun install
    bun run build -- ttf::${FONT_NAME}
EOF

WORKDIR ${BUILD_DIR}/src/glyphs
COPY --link nerd/glyphs .

WORKDIR ${BUILD_DIR}
COPY --link nerd/font-patcher .

WORKDIR ${BUILD_DIR}
COPY --link ./src/docker_run.py .
RUN chmod +x docker_run.py

ENV FONT_NAME=${FONT_NAME}
CMD [ "/bin/bash", "-c", "time ./docker_run.py" ]
