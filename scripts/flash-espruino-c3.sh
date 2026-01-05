#!/usr/bin/env bash
set -e

PORT="${1:-/dev/ttyUSB0}"
ROOT="${2:-/home/simon/dev/espruino/Espruino-fix-2649}"
BUILD="$ROOT/bin/build"
IDF="/home/simon/dev/esp/esp-idf-v4.4.8"
PY="/home/simon/.espressif/python_env/idf4.4_py3.10_env/bin/python"

if [ ! -r "$PORT" ]; then
  echo "ERROR: Port not readable: $PORT"
  ls -l "$PORT" 2>/dev/null || true
  echo "If needed:"
  echo "  sudo chgrp dialout $PORT && sudo chmod 660 $PORT"
  exit 1
fi

cd "$BUILD"

"$PY" "$IDF/components/esptool_py/esptool/esptool.py" \
  -p "$PORT" -b 460800 --before default_reset --after hard_reset --chip esp32c3 \
  write_flash --flash_mode dio --flash_size detect --flash_freq 80m \
  0x0 bootloader/bootloader.bin \
  0x8000 partition_table/partition-table.bin \
  0x10000 espruino.bin
