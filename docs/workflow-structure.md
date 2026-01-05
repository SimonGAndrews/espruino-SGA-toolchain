# Espruino ESP32-C3 (ESP-IDF v4.4.8)
## Build & Flash Workflow (WSL2 / Ubuntu 22.04)

---

## 1. Purpose & Scope

This document defines a known-good, repeatable workflow for building and flashing Espruino on targets including Espressif devices  (eg ESP32-C3) using:

* Windows 11
* WSL2 (Ubuntu 22.04)
* ESP-IDF v4.4.8
* Espruino’s native Makefile-based build system

The goal is to provide a stable, easy to use development loop that:

* Uses ESP-IDF only as a toolchain
* Avoids ESP-IDF project generation
* Avoids CMake / idf.py target management conflicts
* Works reliably under WSL2
* Scales to multiple worktrees and future targets#
* Builds all Espruino targets

This workflow has been validated end-to-end with successful builds and flashing.

---

## 2. Environment Overview

### Host System
* Windows 11
* WSL2 enabled

### Linux Environment
* Ubuntu 22.04 (WSL2)

### Toolchain
* ESP-IDF v4.4.8
* Espressif-managed Python virtual environment
* esptool.py from ESP-IDF v4.4.8

### Example Target Hardware
* ESP32-C3
* USB-Serial via:
  * CH340
  * ESP-PROG (USB-Serial + JTAG)

---

## 3. Repository Layout & Worktrees

This toolchain uses Git worktrees so each branch can live in its own
development folder. A worktree is a full checkout that points at a specific
branch in the local Espruino repo, letting you keep multiple branches
side-by-side without recloning or switching back and forth. As changes are
developed in a branch, they can then be pushed up to the master Espruino remote
repository.

The toolchain docs and scripts are kept in a separate repo:

    <TOOLCHAIN_ROOT>

    eg ~/dev/espruino/espruino-SGA-toolchain

Bootstrap order for a clean restore:

1. Clone the toolchain repo

   ```bash
   git clone https://github.com/SimonGAndrews/espruino-SGA-toolchain <TOOLCHAIN_ROOT>
   ```
2. Install ESP-IDF under `~/dev/esp`
   See `docs/Toolchain-Setup-Reference.md` for the full install steps.
3. Create Espruino worktrees under `~/dev/espruino`

The local Espruino checkout uses a bare repository with multiple worktrees.

Example layout:

    ~/dev/espruino/
      ├─ Espruino-admin.git        (bare repo)
      ├─ Espruino-master           (clean upstream master)
      └─ Espruino-fix-2649         (development branch)

Key points:

* All builds are performed inside a worktree
* Flash scripts accept the worktree path as an argument
* Multiple worktrees can be built and flashed independently

---

## 4. ESP-IDF Version Management

### 4.1 Supported Versions

* ESP-IDF v4.4.8 — required and supported
* ESP-IDF v5.x — installed but not used in this workflow

IDF versions are not switched dynamically; each is enabled explicitly.

### 4.2 IDF Enable Scripts

ESP-IDF environments are activated using small helper scripts.

Example (IDF 4.4.8):

    <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh

This script:
* Sets IDF_PATH
* Updates PATH
* Activates the Espressif Python environment

Important:
IDF scripts must be sourced, not executed.

Example:

    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh

---

## 5. Espruino Build Process

### 5.1 Build Location

All builds are run from the Espruino repository root:

    ~/dev/espruino/Espruino-fix-2649

Builds must not be run from:
* targets/
* bin/
* bin/build/

### 5.2 Build Command

The authoritative build command is:

    make BOARD=ESP32C3_IDF4

This command:

* Selects the correct ESP-IDF integration
* Generates sdkconfig, partition tables, and linker scripts
* Invokes ESP-IDF internally as required
* Produces flash-ready binaries

No direct use of idf.py build is required or recommended.

### 5.3 Build Outputs

Build artifacts are generated under:

    bin/build/

Key files used for flashing:

    bin/build/bootloader/bootloader.bin
    bin/build/partition_table/partition-table.bin
    bin/build/espruino.bin

A versioned release bundle is also produced under:

    bin/espruino_<version>_esp32c3/

---

## 6. Flashing Strategy (Trusted Method)

### 6.1 Rationale

Flashing is performed using esptool.py directly, rather than idf.py flash.

This avoids:
* CMake cache mismatches
* set-target conflicts
* ESP-IDF project assumptions
* Accidental regeneration of sdkconfig

The flash command is taken directly from the Espruino build output, ensuring consistency.

---

### 6.2 Flash Script: flash-espruino-c3.sh

A helper script standardises flashing across worktrees.

Location:

    <TOOLCHAIN_ROOT>/scripts/flash-espruino-c3.sh

Arguments:
1. Serial port (default: /dev/ttyUSB0)
2. Espruino worktree root

The script:
* Validates serial port access
* Changes to the correct build directory
* Invokes esptool.py with known-good offsets

### 6.3 Flash Addresses

The following flash layout is used:

* Bootloader        @ 0x0000
* Partition table   @ 0x8000
* Espruino firmware @ 0x10000

---

## 7. Serial Port & Permissions (WSL2)

Under WSL2, USB devices are attached using usbipd.

The ESP32-C3 serial device typically appears as:

    /dev/ttyUSB0

WSL may not run a full udevd, so permissions may need to be fixed manually:

    sudo chgrp dialout /dev/ttyUSB0
    sudo chmod 660 /dev/ttyUSB0

The user must be a member of the dialout group.

---

## 8. Daily Development Workflow

This is the recommended daily loop.

### Step 1: Enable ESP-IDF

    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh

### Step 2: Build Espruino

    cd ~/dev/espruino/Espruino-fix-2649
    make BOARD=ESP32C3_IDF4

### Step 3: Flash Firmware

    <TOOLCHAIN_ROOT>/scripts/flash-espruino-c3.sh \
      /dev/ttyUSB0 \
      ~/dev/espruino/Espruino-fix-2649

### Step 4: Open Serial Monitor

    picocom -b 115200 /dev/ttyUSB0

---

## 9. Monitoring (To Be Completed)

Serial monitoring is currently performed using:

* picocom
* idf.py monitor (optional)

USB-JTAG and monitoring behaviour under WSL2 varies by hardware and driver.

This section will be expanded once a fully stable monitoring strategy is finalised for:
* ESP32-C3
* ESP32-S3
* ESP-PROG (JTAG)


### 9.1 Status

Serial monitoring is **intentionally deferred**.

Build and flash workflows are validated and stable; monitoring is still under evaluation due to:

- USB-JTAG instability under WSL
- CDC device enumeration inconsistency
- VS Code terminal sensitivity during serial attach

---

### 9.2 Current Position

- `picocom` works in principle with USB-Serial adapters
- USB-JTAG CDC is unreliable under WSL
- Final REPL workflow will be documented once stability is confirmed

This is a **known open item**.

---

## 10. Known Pitfalls & Design Decisions

* Do not run idf.py build directly
* Do not use ESP-IDF project creation
* Do not use idf.py set-target
* Do not regenerate sdkconfig manually
* Always trust the flash command emitted by the Espruino build
* Keep ESP-IDF usage strictly as a toolchain

These decisions are intentional and prevent subtle build breakage.

---

## 11. Future Work

* ESP32-S3 support
* ESP-IDF v5 migration
* JTAG debugging via ESP-PROG
* Stable serial/JTAG monitoring under WSL2
* Optional VS Code integration (non-intrusive)

---

Status:
* Build validated
* Flash validated
* Monitor finalisation pending
