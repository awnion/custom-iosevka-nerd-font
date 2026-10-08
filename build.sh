#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

BUILD_DIR=/build
FONT_NAME=${FONT_NAME:-afio}
BUILD_PLAN=${BUILD_PLAN:-private-build-plans.toml}
OUTPUT_DIR=$(pwd)/_output
IMAGE=${IMAGE:-ghcr.io/awnion/custom-iosevka-nerd-font}
IMAGE_REF=${IMAGE_REF:-}
VERDA_CACHE=${VERDA_CACHE:-}

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [ -z "$IMAGE_REF" ]; then
    VERSION=$(cat VERSION | tr -d '[:space:]')
    IMAGE_REF="${IMAGE}:${VERSION}"

    if docker pull "$IMAGE_REF" 2>/dev/null; then
        echo "Using pre-built image: $IMAGE_REF"
    else
        echo "Image $IMAGE_REF not found, building locally..."
        docker buildx build \
            --load \
            --iidfile "$OUTPUT_DIR"/iddfile \
            .
        IMAGE_REF=$(cat "$OUTPUT_DIR"/iddfile)
    fi
else
    echo "Using provided image: $IMAGE_REF"
fi

echo "Building font '$FONT_NAME' using plan '$BUILD_PLAN' ..."

CACHE_MOUNT=()
if [ -n "$VERDA_CACHE" ]; then
    mkdir -p "$VERDA_CACHE/build" "$VERDA_CACHE/dist"
    VERDA_CACHE=$(cd "$VERDA_CACHE" && pwd)
    echo "Using verda cache: $VERDA_CACHE"
    CACHE_MOUNT=(
        -v "$VERDA_CACHE/build":${BUILD_DIR}/iosevka/.build
        -v "$VERDA_CACHE/dist":${BUILD_DIR}/iosevka/dist
    )
fi

TTY_ARGS=()
if [ -t 1 ]; then
    TTY_ARGS=(-t)
fi

docker run --rm "${TTY_ARGS[@]}" \
    -e FONT_NAME="$FONT_NAME" \
    -e PATCH_JOBS \
    -v "$OUTPUT_DIR":/output \
    -v "$(pwd)/$BUILD_PLAN":${BUILD_DIR}/iosevka/private-build-plans.toml:ro \
    "${CACHE_MOUNT[@]}" \
    "$IMAGE_REF" -c "\
        cd ${BUILD_DIR}/iosevka && \
        if [ ! -f .build/.verda-build-journal ] && [ -d .build-seed ]; then \
            mkdir -p .build && cp -a .build-seed/. .build/; \
        fi && \
        time bun run build -- ttf::${FONT_NAME} && \
        cd ${BUILD_DIR} && \
        time python3 nerd-patcher.py"
