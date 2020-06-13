#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

docker build -t iosevka_builder .
docker run --rm -it -v $(pwd)/_output:/output iosevka_builder
