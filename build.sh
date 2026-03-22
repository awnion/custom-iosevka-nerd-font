#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

BUILD_DIR=/build
FONT_NAME=${FONT_NAME:-afio}
BUILD_PLAN=${BUILD_PLAN:-private-build-plans.toml}
OUTPUT_DIR=$(pwd)/_output

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

docker buildx build \
    --load \
    --iidfile "$OUTPUT_DIR"/iddfile \
    .

IMAGE_ID=$(cat "$OUTPUT_DIR"/iddfile)

echo "Building font '$FONT_NAME' using plan '$BUILD_PLAN' ..."

docker run --rm -t \
    -v "$OUTPUT_DIR":/output \
    -v "$(pwd)/$BUILD_PLAN":${BUILD_DIR}/iosevka/private-build-plans.toml:ro \
    "$IMAGE_ID" -c "\
        cd ${BUILD_DIR}/iosevka && \
        bun run build -- ttf::${FONT_NAME} && \
        cd ${BUILD_DIR} && \
        python3 docker_run.py"
