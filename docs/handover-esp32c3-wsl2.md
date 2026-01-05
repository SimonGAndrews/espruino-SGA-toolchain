# Handover - Espruino ESP32-C3 Build and Flash Workflow (WSL2 / ESP-IDF v4.4.8)

## Context and Objective

This handover documents the current, validated state of the Espruino ESP32-C3
development environment under WSL2, including:

- Installed tools and versions
- Repository structure and worktree usage
- A proven, repeatable build and flash workflow
- Design decisions taken to avoid ESP-IDF / CMake conflicts
- Known constraints and intentional exclusions (monitoring, IDF5, VS Code plugin use)

The goal is that a new thread, assistant, or development session can immediately
continue work without re-discovering environment details or repeating setup or
debugging.

A full reference workflow document exists at:

    <TOOLCHAIN_ROOT>/docs/workflow-structure.md

This handover summarizes and contextualizes that document.

---

## Host and Platform

### Host OS

- Windows 11

### Virtualization

- WSL2 enabled
- Single active distribution:
  - Ubuntu 22.04 LTS

### USB Access

- USB devices are attached to WSL using `usbipd-win`
- ESP32-C3 devices tested via:
  - CH340 USB-Serial
  - Olimex ESP-PROG (USB-Serial + JTAG)

---

## Tools Installed (Validated)

### Core Toolchain

- ESP-IDF v4.4.8 (required, authoritative)
- ESP-IDF v5.2.2 (installed but intentionally unused in this workflow)

ESP-IDF installations are located under:

    /home/simon/dev/esp/

Each version is enabled explicitly via a shell script.

### ESP-IDF Enable Scripts

- `<TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh`
- `<TOOLCHAIN_ROOT>/scripts/idf5.2.2.sh`

These scripts:

- Export `IDF_PATH`
- Extend `PATH`
- Activate Espressif's Python virtual environment

They must be sourced, not executed:

    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh

### Python

- Espressif-managed virtualenv created by IDF install
- Used explicitly when invoking `esptool.py`

### Flashing Tools

- `esptool.py` from ESP-IDF v4.4.8
- Invoked directly (not via `idf.py flash`)

### Serial Tools

- `picocom` installed for console access
- `idf.py monitor` available but not yet standardized

---

## Repository and Worktree Layout

The Espruino repository is managed using a bare repo plus worktrees approach.
The toolchain docs and scripts live separately at:

    <TOOLCHAIN_ROOT>

Canonical layout:

    ~/dev/espruino/
      - Espruino-admin.git        (bare repository)
      - Espruino-master           (clean upstream master)
      - Espruino-fix-2649         (active development branch)

Key points:

- All builds are performed from a worktree root
- Flashing scripts take the worktree path as an argument
- Multiple worktrees can be built and flashed independently without interference

---

## Build Strategy (Trusted Method)

### Philosophy

Espruino's Makefile-based build system is the sole authority for:

- Board selection
- SDK configuration
- Partition layout
- Linker scripts
- ESP-IDF integration

ESP-IDF is treated strictly as a toolchain, not as a project manager.

### Build Location

Builds are always run from the worktree root, for example:

    ~/dev/espruino/Espruino-fix-2649

Builds must not be run from:

- `targets/`
- `bin/`
- `bin/build/`

### Build Command (ESP32-C3, IDF4)

    make BOARD=ESP32C3_IDF4

This command:

- Selects the IDF4 integration
- Generates `sdkconfig` and partition files automatically
- Emits the authoritative flash command for this build

Always use the flash command emitted by the Espruino build.

---

## Flash Strategy (Trusted Method)

### Flash Command Source

Do not use `idf.py flash`. The correct flash command is printed by the build and
should be executed directly.

### Example (Typical) Flash Command

The exact command varies by build; always use the one printed after `make`.
Typical pattern:

    python $IDF_PATH/components/esptool_py/esptool/esptool.py \
      -p /dev/ttyACM0 -b 460800 --before=default_reset --after=hard_reset \
      --chip esp32c3 write_flash --flash_mode dio --flash_freq 80m \
      --flash_size 2MB 0x0 bootloader.bin 0x8000 partition-table.bin \
      0x10000 espruino.bin

### Notes

- The build output is the source of truth for offsets and binaries.
- Use the ESP-IDF v4.4.8 Python environment.

---

## Known Constraints and Intentional Exclusions

- Monitoring is not finalized under WSL2.
- ESP-IDF v5 is installed but intentionally not used.
- VS Code ESP-IDF plugin is intentionally avoided in this workflow.

---

## Design Decisions (Summary)

- Do not run `idf.py build` directly
- Do not use ESP-IDF project creation
- Do not use `idf.py set-target`
- Do not regenerate `sdkconfig` manually
- Always trust the flash command emitted by the Espruino build
- Keep ESP-IDF usage strictly as a toolchain

These decisions are intentional and prevent subtle build breakage.

---

## Status

- Build validated
- Flash validated
- Monitor finalization pending
