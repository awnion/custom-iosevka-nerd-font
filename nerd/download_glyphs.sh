#!/bin/bash

set -e

mkdir -p glyphs
cd glyphs

BASE_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/src/glyphs/"

xargs -n1 -P20 -I{} curl --create-dirs -sLo {} "$BASE_URL"{} <<EOF
"original-source.otf"
"devicons.ttf"
"powerline-symbols/PowerlineSymbols.otf"
"PowerlineExtraSymbols.otf"
"Pomicons.otf"
"font-awesome/FontAwesome.otf"
"font-awesome-extension.ttf"
"Unicode_IEC_symbol_font.otf"
"materialdesignicons-webfont.ttf"
"weather-icons/weathericons-regular-webfont.ttf"
"font-logos.ttf"
"octicons.ttf"
"codicons/codicon.ttf"
EOF
