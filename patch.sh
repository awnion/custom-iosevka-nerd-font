#!/bin/bash

set -e
set -v

docker build -t fontforge_test .

mkdir -p build_dir
# (cd build_dir && curl -OL https://github.com/ryanoasis/nerd-fonts/raw/master/font-patcher)
cp -f font-patcher build_dir/font-patcher

mkdir -p build_dir/src
rm -rf build_dir/src/glyphs
cp -rf glyphs build_dir/src/glyphs

docker run -it \
    -v $(pwd)/build_dir/:/build/ \
    fontforge_test \
    /bin/bash -c "cd /build; find /build/dist/iosevka-custom/ttf -name '*.ttf' -print0 | xargs -0 -i python font-patcher -c -q --no-progressbars {}" 
