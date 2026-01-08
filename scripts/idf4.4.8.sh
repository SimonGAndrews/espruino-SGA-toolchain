#!/usr/bin/env bash
set -e

# Enable ESP-IDF v4.4.8 environment in the current shell.
# export.sh sets IDF_PATH, updates PATH, and wires up idf.py/esptool for this session.
# Usage: source scripts/idf4.4.8.sh
# Defaults (overridable via env): IDF_PATH
# Example:
#   IDF_PATH=$HOME/dev/esp/esp-idf-v4.4.8 source scripts/idf4.4.8.sh
#
# Prerequisite: ESP-IDF is cloned locally in that path and install.sh has been run
# for this version (to set up the Python env and tools).
#
# Note:  export.sh is the ESP‑IDF environment setup script. When you source it, it:
#  - Sets key environment variables (IDF_PATH, toolchain paths, Python virtualenv paths).
#  - Updates PATH so IDF tools (idf.py, compiler, esptool.py) are found.
#  - Loads IDF’s helper functions and checks/install requirements for that IDF version.
#  In short: it makes the ESP‑IDF toolchain available in the current shell session.


export IDF_PATH="${IDF_PATH:-$HOME/dev/esp/esp-idf-v4.4.8}"
if [ ! -f "$IDF_PATH/export.sh" ]; then
  echo "ERROR: export.sh not found under: $IDF_PATH"
  exit 1
fi
. "$IDF_PATH/export.sh" >/dev/null 2>&1
echo "ESP-IDF enabled: $IDF_PATH"
idf.py --version
