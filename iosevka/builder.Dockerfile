FROM debian:sid-slim

ARG BUILD_DIR=/build
ARG NODE_VER=14
ARG PREMAKE_VER=5.0.0-alpha15
ARG OTFCC_VER=0.10.4
# Check https://github.com/be5invis/Iosevka/releases for font version
ARG FONT_VERSION=3.1.1

ENV DEBIAN_FRONTEND=noninteractive

RUN true \
    && apt-get update -yqq \
    && apt-get install --no-install-recommends -yqq \
        build-essential \
        curl \
        ca-certificates \
        ttfautohint \
    && curl -sL https://deb.nodesource.com/setup_${NODE_VER}.x | bash - \
    && apt-get install --no-install-recommends -yqq \
        nodejs \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete


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
