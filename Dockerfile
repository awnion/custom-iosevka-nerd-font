# syntax=docker/dockerfile:1.4

ARG BUILD_DIR=/build
ARG FONT_NAME=afio

ARG NODE_VER=14
ARG PREMAKE_VER=5.0.0-alpha15
ARG OTFCC_VER=0.10.4
# Check https://github.com/be5invis/Iosevka/releases for font version
ARG FONT_VERSION=15.1.0

################################################################

FROM debian:bullseye-slim AS base_builder

ARG BUILD_DIR
ARG NODE_VER

ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DIR=${BUILD_DIR}

RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt <<EOF
    set -e
    apt-get update -yqq
    apt-get install --no-install-recommends -yqq \
        build-essential \
        ca-certificates \
        curl \
        fontforge \
        python3-fontforge \
        ttfautohint
    curl -sL https://deb.nodesource.com/setup_${NODE_VER}.x | bash -
    apt-get install --no-install-recommends -yqq nodejs
EOF


FROM base_builder AS builder_otf

ARG BUILD_DIR
ARG OTFCC_VER
ARG PREMAKE_VER

WORKDIR ${BUILD_DIR}
# Install premake
RUN curl -sSLo premake5.tar.gz https://github.com/premake/premake-core/releases/download/v${PREMAKE_VER}/premake-${PREMAKE_VER}-linux.tar.gz \
    && tar xvf premake5.tar.gz \
    && mv premake5 /usr/local/bin/premake5 \
    && rm premake5.tar.gz

# Build&install OTFCC
RUN curl -sSLo otfcc.tar.gz https://github.com/caryll/otfcc/archive/v${OTFCC_VER}.tar.gz \
    && tar xvf otfcc.tar.gz \
    && rm otfcc.tar.gz \
    && mv otfcc-${OTFCC_VER} otfcc \
    && (cd otfcc && premake5 gmake) \
    && (cd otfcc/build/gmake && make config=release_x64) \
    && mv otfcc/bin/release-x64/otfccbuild /usr/local/bin/otfccbuild \
    && mv otfcc/bin/release-x64/otfccdump /usr/local/bin/otfccdump \
    && rm -rf otfcc


FROM base_builder AS builder_iosevka

ARG FONT_NAME
ARG BUILD_DIR
ARG FONT_VERSION


WORKDIR ${BUILD_DIR}
# Download original font source
RUN curl -sSLo v${FONT_VERSION}.tar.gz https://github.com/be5invis/Iosevka/archive/v${FONT_VERSION}.tar.gz \
    && tar xvf v${FONT_VERSION}.tar.gz \
    && rm v${FONT_VERSION}.tar.gz \
    && mv Iosevka-${FONT_VERSION} Iosevka

WORKDIR ${BUILD_DIR}/Iosevka
RUN true \
    && grep -v ttf2woff package.json > new_package.json \
    && mv new_package.json package.json \
    && npm install

COPY --from=builder_otf /usr/local/bin/otfccbuild /usr/local/bin/otfccbuild
COPY --from=builder_otf /usr/local/bin/otfccdump /usr/local/bin/otfccdump

COPY private-build-plans.toml .
RUN echo "...Building fonts: May take a few minutes..." \
    && npm run build -- ttf::${FONT_NAME}

WORKDIR ${BUILD_DIR}/src/glyphs
COPY nerd/glyphs .

WORKDIR ${BUILD_DIR}
COPY nerd/font-patcher .

WORKDIR ${BUILD_DIR}
COPY docker_run.py .
RUN chmod +x docker_run.py

ENV FONT_NAME=${FONT_NAME}
CMD [ "/bin/bash", "-c", "time ./docker_run.py" ]
