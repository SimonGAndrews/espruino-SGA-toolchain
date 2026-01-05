#!/usr/bin/env bash
set -e
export IDF_PATH="${IDF_PATH:-$HOME/dev/esp/esp-idf-v5.2.2}"
if [ ! -f "$IDF_PATH/export.sh" ]; then
  echo "ERROR: export.sh not found under: $IDF_PATH"
  exit 1
fi
. "$IDF_PATH/export.sh" >/dev/null 2>&1
echo "ESP-IDF enabled: $IDF_PATH"
idf.py --version
