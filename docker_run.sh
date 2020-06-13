#!/bin/bash

set -e

find $BUILD_DIR/Iosevka/dist/iosevka-custom/ttf -name *.ttf | \
    xargs -i -n 1 -P 8 python3 font-patcher -c -q -out /output {}
