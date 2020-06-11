#!/bin/bash

set -e

export DOCKER_BUILDKIT=1

docker build -t iosevka_builder -f iosevka/builder.Dockerfile .
docker build -t iosevka_patcher -f iosevka/patcher.Dockerfile .

docker run --rm -it \
    -v $(pwd)/build_dir:/build/build_dir \
    iosevka_patcher \
    bash -c 'ls ttf/ | xargs -i python3 font-patcher -c -out build_dir ttf/{}'
