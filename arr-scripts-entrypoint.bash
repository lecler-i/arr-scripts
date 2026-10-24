#!/usr/bin/with-contenv bash
# Replaces lidarr/setup.bash. Packages are baked into the image; this only
# copies services/configs from $ARR_SCRIPT_ROOT into place for s6.
set -euo pipefail

SRC="${ARR_SCRIPT_ROOT:-/opt/arr-scripts}"
LOGIN=/custom-services.d
ECONF=/config/extended

BUILD_MARKER="### ARR_SCRIPTS_IMAGE_BUILD: local-checkout"

log() { echo "[arr-scripts] $*"; }

log "================ START ================"
log "source      : $SRC"
log "build marker: $BUILD_MARKER"
log "kernel      : $(uname -srm)"
if [[ -d "$SRC" ]]; then
  log "git HEAD    : $(cat "$SRC/.git-head" 2>/dev/null || echo 'n/a')"
fi

if [[ ! -d "$SRC/lidarr" ]]; then
  log "no clone at $SRC/lidarr — skipping"
  exit 0
fi

log "deploying services"
mkdir -p "$LOGIN/python" "$ECONF"

# services -> /custom-services.d (s6 runs these)
copy() { log "  + $2"; install -m 755 -D "$1" "$2"; }
copy "$SRC/lidarr/Audio.service.bash"          "$LOGIN/Audio"
copy "$SRC/lidarr/AutoConfig.service.bash"     "$LOGIN/AutoConfig"
copy "$SRC/lidarr/Video.service.bash"          "$LOGIN/Video"
copy "$SRC/lidarr/TidalVideoDownloader.bash"   "$LOGIN/TidalVideoDownloader"
copy "$SRC/lidarr/AutoArtistAdder.bash"        "$LOGIN/AutoArtistAdder"
copy "$SRC/lidarr/UnmappedFilesCleaner.bash"   "$LOGIN/UnmappedFilesCleaner"
copy "$SRC/lidarr/ARLChecker"                  "$LOGIN/ARLChecker"
copy "$SRC/lidarr/python/ARLChecker.py"        "$LOGIN/python/ARLChecker.py"
copy "$SRC/universal/services/QueueCleaner"    "$LOGIN/QueueCleaner"

# helper scripts -> /config/extended
log "deploying helpers"
copy "$SRC/universal/functions.bash"      "$ECONF/functions"
copy "$SRC/lidarr/PlexNotify.bash"        "$ECONF/PlexNotify.bash"
copy "$SRC/lidarr/LyricExtractor.bash"    "$ECONF/LyricExtractor.bash"
copy "$SRC/lidarr/ArtworkExtractor.bash"  "$ECONF/ArtworkExtractor.bash"
copy "$SRC/lidarr/BeetsTagger.bash"       "$ECONF/BeetsTagger.bash"
copy "$SRC/lidarr/sma.ini"                "$ECONF/sma.ini"

# seed configs only when absent — never clobber user settings
log "seeding configs (only if missing)"
seed() { [[ -f "$2" ]] || { log "  + $2"; install -m 755 -D "$1" "$2"; }; }
seed "$SRC/lidarr/extended.conf"             /config/extended.conf
seed "$SRC/lidarr/beets-config.yaml"         "$ECONF/beets-config.yaml"
seed "$SRC/lidarr/beets-config-lidarr.yaml"  "$ECONF/beets-config-lidarr.yaml"
seed "$SRC/lidarr/beets-genre-whitelist.txt" "$ECONF/beets-genre-whitelist.txt"
seed "$SRC/lidarr/deemix_config.json"        "$ECONF/deemix_config.json"
seed "$SRC/lidarr/tidal-dl.json"             "$ECONF/tidal-dl.json"

chmod -R 777 "$ECONF" "$LOGIN" 2>/dev/null || true
log "================ DONE ================="
