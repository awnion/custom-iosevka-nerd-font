#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

BUILD_DIR=/build
FONT_NAME=${FONT_NAME:-afio}
BUILD_PLAN=${BUILD_PLAN:-private-build-plans.toml}
OUTPUT_DIR=$(pwd)/_output
IMAGE=${IMAGE:-ghcr.io/awnion/custom-iosevka-nerd-font}
IMAGE_REF=${IMAGE_REF:-}

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

docker run --rm -t \
    -v "$OUTPUT_DIR":/output \
    -v "$(pwd)/$BUILD_PLAN":${BUILD_DIR}/iosevka/private-build-plans.toml:ro \
    "$IMAGE_REF" -c "\
        cd ${BUILD_DIR}/iosevka && \
        bun run build -- ttf::${FONT_NAME} && \
        cd ${BUILD_DIR} && \
        python3 docker_run.py"
