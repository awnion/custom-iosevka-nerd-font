#!/bin/bash

set -e

GLYPHS=$(cat <<-END
devicons.ttf
font-awesome-extension.ttf
font-logos.ttf
FontAwesome.otf
materialdesignicons-webfont.ttf
octicons.ttf
original-source.otf
Pomicons.otf
PowerlineExtraSymbols.otf
PowerlineSymbols.otf
Unicode_IEC_symbol_font.otf
weathericons-regular-webfont.ttf
END
)

cd glyphs

for f in $GLYPHS
do
    curl -sOL "https://github.com/ryanoasis/nerd-fonts/raw/master/src/glyphs/$f" &
done

wait
