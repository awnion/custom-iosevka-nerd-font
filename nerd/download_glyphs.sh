#!/bin/bash

set -e

mkdir -p glyphs
cd glyphs

BASE_URL="https://github.com/ryanoasis/nerd-fonts/raw/master/src/glyphs"

xargs -n1 -P20 -I{} curl --create-dirs -svLo {} "$BASE_URL"/{} <<EOF
"codicons/codicon.ttf"
"devicons/devicons.ttf"
"font-awesome/FontAwesome.otf"
"materialdesign/MaterialDesignIconsDesktop.ttf"
"materialdesign/materialdesignicons-webfont.ttf"
"octicons/octicons.ttf"
"pomicons/Pomicons.otf"
"powerline-extra/PowerlineExtraSymbols.otf"
"powerline-symbols/PowerlineSymbols.otf"
"weather-icons/weathericons-regular-webfont.ttf"
"Unicode_IEC_symbol_font.otf"
"font-awesome-extension.ttf"
"font-logos.ttf"
"original-source.otf"
"extraglyphs.sfd"
EOF
