FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        fontforge \
        ca-certificates \
        curl \
        python-pip \
        python-fontforge \
    && pip install configparser

# RUN mkdir -p /app

# RUN curl -o /app/font-patcher https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/font-patcher
# RUN chmod 700 /app/font-patcher

# COPY glyphs/ /app/src/glyphs/

# WORKDIR /app

# COPY patch.sh patch.sh
# RUN chmod 700 patch.sh
