#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

OUTPUT_DIR=$(pwd)/_output

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
docker buildx build \
    --load \
    --iidfile "$OUTPUT_DIR"/iddfile \
    .
IMAGE_ID=$(cat "$OUTPUT_DIR"/iddfile)
echo "Run docker ..."
docker run --rm -t -v "$OUTPUT_DIR":/output "$IMAGE_ID"
