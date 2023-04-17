#!/bin/bash

set -e

sudo mkdir -p /usr/share/fonts/truetype/afio
sudo cp -f -v _output/*.ttf /usr/share/fonts/truetype/afio
