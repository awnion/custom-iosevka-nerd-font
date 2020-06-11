ARG BUILD_DIR=/build


FROM iosevka_builder AS builder

ARG BUILD_DIR

COPY iosevka/private-build-plans.toml .
RUN npm run build -- ttf::iosevka-custom


FROM debian:sid-slim

ARG BUILD_DIR

ENV DEBIAN_FRONTEND=noninteractive

RUN true \
    && apt-get update -yqq \
    && apt-get install --no-install-recommends -yqq \
        fontforge \
        python3-pip \
        python3-fontforge \
    && pip3 install configparser \
    && find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete

WORKDIR ${BUILD_DIR}
COPY glyphs src/glyphs/
COPY font-patcher .
COPY --from=builder ${BUILD_DIR}/Iosevka/dist/iosevka-custom/ttf ttf/
