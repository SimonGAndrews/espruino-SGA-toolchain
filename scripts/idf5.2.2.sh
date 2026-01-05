#!/usr/bin/env bash
set -e
export IDF_PATH="$HOME/dev/esp/esp-idf-v5.2.2"
. "$IDF_PATH/export.sh" >/dev/null 2>&1
echo "ESP-IDF enabled: $IDF_PATH"
idf.py --version
