FROM lscr.io/linuxserver/lidarr:latest

# Bakes the "install" half of lidarr/setup.bash. Commands, flags and package
# lists are kept byte-for-byte identical to upstream; only the curl'ing of
# scripts at the end moves to the runtime entrypoint.

RUN apk add -U --upgrade --no-cache \
      tidyhtml \
      musl-locales \
      musl-locales-lang \
      flac \
      jq \
      xq \
      git \
      gcc \
      ffmpeg \
      imagemagick \
      opus-tools \
      opustags \
      python3-dev \
      libc-dev \
      uv \
      parallel \
      npm \
 && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing atomicparsley \
 && npm install -g miraclx/freyr-js

RUN uv pip install --system --upgrade --break-system-packages \
      jellyfish \
      beautifulsoup4 \
      yt-dlp \
      beets \
      yq \
      pyxDamerauLevenshtein \
      pyacoustid \
      requests \
      colorama \
      python-telegram-bot \
      pylast \
      mutagen \
      r128gain \
      tidal-dl \
      deemix \
      langdetect \
      apprise

# SMA, as upstream clones it
RUN git clone --depth 1 https://github.com/mdhiggins/sickbeard_mp4_automator.git /usr/local/sma \
 && touch /usr/local/sma/config/sma.log \
 && chgrp users /usr/local/sma/config/sma.log \
 && chmod g+w /usr/local/sma/config/sma.log \
 && uv pip install --system --break-system-packages -r /usr/local/sma/setup/requirements.txt

# The scripts themselves, so the image runs standalone. Mount a clone over
# ARR_SCRIPT_ROOT to override them at runtime.
COPY lidarr/ /opt/arr-scripts/lidarr/
COPY universal/ /opt/arr-scripts/universal/

# Prove which checkout this image was built from.
ARG GIT_HEAD=unknown
RUN echo "${GIT_HEAD}" > /opt/arr-scripts/.git-head \
 && echo "image built from ${GIT_HEAD}" \
 && cat /opt/arr-scripts/.git-head

# Copies services from $ARR_SCRIPT_ROOT instead of curl'ing GitHub.
COPY arr-scripts-entrypoint.bash /custom-cont-init.d/10-arr-scripts.bash
RUN chmod 755 /custom-cont-init.d/10-arr-scripts.bash

ENV ARR_SCRIPT_ROOT=/opt/arr-scripts
