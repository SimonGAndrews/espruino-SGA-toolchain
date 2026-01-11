# Espruino Toolchain Docs and Scripts

Local documentation and scripts for Espruino-related development work. This
repo is kept separate from upstream worktrees to avoid pushing internal notes
or workflows to the public Espruino repository.

## Contents

| Document | Purpose |
| --- | --- |
| `Toolchain-Setup-Reference.md` | Full toolchain setup reference for WSL2, IDF versions, and validation steps. |
| `Troubleshooting-Matrix.md` | Symptom-to-cause matrix covering setup, build, USB, and flashing issues. |
| `handover-esp32c3-wsl2.md` | Environment handover for the validated ESP32-C3 build/flash workflow. |
| `workflow-structure.md` | End-to-end build and flash workflow with worktree and IDF4 guidance. |
| `wsl-usb-setup.md` | USB attach/permissions guide for WSL2 using usbipd-win and serial/JTAG devices. |
| `addendum.md` | Decision notes and clarifications on shell stability, VS Code extension use, and monitoring. (points included in other files) |

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/idf4.4.8.sh` | Activate ESP-IDF v4.4.8 (exports `IDF_PATH` and environment). |
| `scripts/idf5.2.2.sh` | Activate ESP-IDF v5.2.2 (installed but not used in the current workflow). |
| `scripts/flash-espruino-c3.sh` | Flash helper for ESP32-C3 builds using esptool from IDF v4.4.8. |
| `scripts/monitor-espruino-c3.sh` | ESP-IDF monitor helper for ESP32-C3 builds. |

Minimal daily loop (after setup):

    source <TOOLCHAIN_ROOT>/scripts/env.sh
    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh
    cd "$ESPRUINO_ROOT" && make BOARD=ESP32C3_IDF4
    <TOOLCHAIN_ROOT>/scripts/flash-espruino-c3.sh
    <TOOLCHAIN_ROOT>/scripts/monitor-espruino-c3.sh /dev/ttyUSB0 "$ESPRUINO_ROOT"

Status:

 - A fully validated Espruino toolchain under WSL

 - A repeatable build + flash workflow

 - Clear USB/WSL operational guidance

 - A troubleshooting matrix grounded in real failures

 - Explicit decision records (VS Code plugin, JTAG, monitoring)

 - ESP-IDF monitor standardised for serial access

 - Clean handover-ready documentation that will stand the test of time

 - Most importantly, you’ve turned what could have been a fragile “it works on my machine” setup into a durable engineering baseline.

Natural next steps would be:

 - ESP32-S3 bring-up

 - IDF5 migration planning

 - Native Linux comparison (to retire WSL pain points)

 - Folding this into a VS Code Codex or onboarding guide
