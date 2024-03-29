#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

OUTPUT_DIR=$(pwd)/_output
IMAGE_TAG=afio_builder

rm -rf "$OUTPUT_DIR"
echo "Build docker image: $IMAGE_TAG"
docker buildx build -t $IMAGE_TAG .
echo "Run docker ..."
docker run --rm -it -v "$OUTPUT_DIR":/output $IMAGE_TAG
