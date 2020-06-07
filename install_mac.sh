#!/bin/bash

set -e
set -v

# find ~/Library/Fonts/ -name 'iosevka-custom*' -delete
cp build_dir/dist/iosevka-custom/ttf/* ~/Library/Fonts/
