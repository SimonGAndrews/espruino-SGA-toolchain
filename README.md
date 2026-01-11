# Espruino SGA Toolchain

Documentation and helper scripts for Espruino development work under MS Mindows WSL in VScode, kept
separate from upstream Espruino repository. 

Status - Operational toolchain testede with Espruino for ESP32C3 build and flash.
See /docs/workflow-structure.md for workflow details.

## Repository structure

- `docs/` - Setup references, workflows, troubleshooting, and handover notes.
- `scripts/` - Small shell helpers for activating IDF versions and flashing.

## Assumptions

Scripts default to the local paths used during setup (see each script header).
If your environment differs, set the documented environment overrides or adjust
the paths in place.

## Bootstrap order

1) Clone this repo to your toolchain root 
2) (for example, `<TOOLCHAIN_ROOT>` or  ~/dev/espruino/espruino-SGA-toolchain).
3) Install ESP-IDF versions under `~/dev/esp`.
4) Create Espruino worktrees under `~/dev/espruino`.

## Quick start

1) Start with `docs/Toolchain-Setup-Reference.md` to validate the toolchain.
2) Follow `docs/workflow-structure.md` for the build/flash flow.
3) Use `docs/Troubleshooting-Matrix.md` if you hit errors.

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
| `scripts/env.sh` | Set `TOOLCHAIN_ROOT` and `ESPRUINO_ROOT` for the current shell. |
| `scripts/idf4.4.8.sh` | Activate ESP-IDF v4.4.8 (exports `IDF_PATH` and environment). |
| `scripts/idf5.2.2.sh` | Activate ESP-IDF v5.2.2 (installed but not used in the current workflow). |
| `scripts/flash-espruino-c3.sh` | Flash helper for ESP32-C3 builds using esptool from IDF v4.4.8. |
| `scripts/monitor-espruino-c3.sh` | Run the ESP-IDF monitor against the built ESP32-C3 ELF. |

Notes:

- `scripts/env.sh` sets defaults and prints the resolved paths.
- `scripts/flash-espruino-c3.sh` supports overrides via `ESPRUINO_PORT`,
  `ESPRUINO_ROOT`, `ESPRUINO_IDF`, and `ESPRUINO_PY`.
- When `ESPRUINO_ROOT` is set (via `env.sh`), flash can be run with no args.
- `scripts/monitor-espruino-c3.sh` supports `TOOLCHAIN_ROOT`, `ESPRUINO_PORT`,
  `ESPRUINO_ROOT`, and `ESPRUINO_BAUD`.
- `scripts/idf4.4.8.sh` and `scripts/idf5.2.2.sh` respect `IDF_PATH` if set.
