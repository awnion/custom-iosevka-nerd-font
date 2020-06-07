#!/bin/bash

set -e
set -v

(cd iosevka && docker build -t  iosevka_build . -f Dockerfile)

rm -rf build_dir
mkdir -p build_dir

cp iosevka/private-build-plans.toml build_dir/private-build-plans.toml

docker run -it -v `pwd`/build_dir:/build iosevka_build ttf::iosevka-custom
