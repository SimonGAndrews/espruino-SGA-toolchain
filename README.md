# Espruino SGA Toolchain

Local documentation and helper scripts for Espruino development work, kept
separate from upstream Espruino repositories so internal setup notes and
workflows stay private.

## Repository structure

- `docs/` - Setup references, workflows, troubleshooting, and handover notes.
- `scripts/` - Small shell helpers for activating IDF versions and flashing.

## Documentation index

| Document | Purpose |
| --- | --- |
| `docs/Toolchain-Setup-Reference.md` | Full toolchain setup reference for WSL2, IDF versions, and validation steps. |
| `docs/Troubleshooting-Matrix.md` | Symptom-to-cause matrix covering setup, build, USB, and flashing issues. |
| `docs/handover-esp32c3-wsl2.md` | Environment handover for the validated ESP32-C3 build/flash workflow. |
| `docs/workflow-structure.md` | End-to-end build and flash workflow with worktree and IDF4 guidance. |
| `docs/wsl-usb-setup.md` | USB attach/permissions guide for WSL2 using usbipd-win and serial/JTAG devices. |
| `docs/addendum.md` | Decision notes and clarifications on shell stability, VS Code extension use, and monitoring. |

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/idf4.4.8.sh` | Activate ESP-IDF v4.4.8 (exports `IDF_PATH` and environment). |
| `scripts/idf5.2.2.sh` | Activate ESP-IDF v5.2.2 (installed but not used in the current workflow). |
| `scripts/flash-espruino-c3.sh` | Flash helper for ESP32-C3 builds using esptool from IDF v4.4.8. |
