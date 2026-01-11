#!/usr/bin/env bash
# Monitor Espruino ESP32-C3 via ESP-IDF's idf_monitor.py.
# Usage: monitor-espruino-c3.sh [PORT] [ESPRUINO_ROOT] [BAUD]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

PORT="${1:-${ESPRUINO_PORT:-/dev/ttyUSB0}}" # Serial device to attach to.
ROOT="${2:-${ESPRUINO_ROOT:-/home/simon/dev/espruino/Espruino-fix-2649}}" # Espruino repo root.
BAUD="${3:-${ESPRUINO_BAUD:-115200}}" # Monitor baud rate.
ELF="$ROOT/bin/build/espruino.elf"

if [ ! -r "$PORT" ]; then
  echo "ERROR: Port not readable: $PORT"
  ls -l "$PORT" 2>/dev/null || true
  echo "If needed:"
  echo "  sudo chgrp dialout $PORT && sudo chmod 660 $PORT"
  exit 1
fi

if [ ! -f "$ELF" ]; then
  echo "ERROR: ELF not found: $ELF"
  exit 1
fi

if [ ! -f "$TOOLCHAIN_ROOT/scripts/idf4.4.8.sh" ]; then
  echo "ERROR: IDF enable script not found: $TOOLCHAIN_ROOT/scripts/idf4.4.8.sh"
  exit 1
fi

# Uses idf_monitor.py directly because this repo isn't an ESP-IDF CMake project.
# shellcheck source=/dev/null
. "$TOOLCHAIN_ROOT/scripts/idf4.4.8.sh"

if [ -z "${IDF_PATH:-}" ]; then
  echo "ERROR: IDF_PATH not set after sourcing IDF script"
  exit 1
fi

if [ ! -f "$IDF_PATH/tools/idf_monitor.py" ]; then
  echo "ERROR: idf_monitor.py not found under: $IDF_PATH"
  exit 1
fi

python "$IDF_PATH/tools/idf_monitor.py" -p "$PORT" -b "$BAUD" "$ELF"
