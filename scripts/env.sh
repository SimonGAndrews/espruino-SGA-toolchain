#!/usr/bin/env bash
# Purpose: set toolchain paths for the current shell session.
# Usage: source this before the daily workflow steps (see docs/workflow-structure.md).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_ROOT="${TOOLCHAIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ESPRUINO_ROOT="${ESPRUINO_ROOT:-$HOME/dev/espruino/Espruino-fix-2649}"

export TOOLCHAIN_ROOT
export ESPRUINO_ROOT

echo "TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT"
echo "ESPRUINO_ROOT=$ESPRUINO_ROOT"
