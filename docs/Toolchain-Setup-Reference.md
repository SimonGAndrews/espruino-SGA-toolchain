# Espruino Toolchain Setup Reference  
## WSL2 + Ubuntu 22.04 (ESP32 / ESP32-C3 / IDF4 Focus)

---

## 1. Purpose & Scope

This document defines the **complete, validated toolchain installation and setup** used for Espruino development in this project.

It complements:

- `workflow-structure.md` (main Espruino workflow)
- `wsl-usb-setup.md` (USB & flashing under WSL)

which can be found in this repo under `docs/`.

This document focuses on:
- Host OS preparation
- Linux toolchain installation
- Node.js tooling
- ESP-IDF (v4.4.8 and v5.x coexistence)
- Environment activation strategy
- Validation steps

The resulting environment **successfully builds and flashes Espruino** for ESP32-C3 under WSL.

---

## 1.1 Bootstrap Order (Recommended)

To restore the workflow from scratch:

1. Clone this toolchain repo to:
   `<TOOLCHAIN_ROOT>`
2. Install ESP-IDF versions under:
   `~/dev/esp`
3. Create Espruino worktrees under:
   `~/dev/espruino`

This keeps toolchain scripts and docs versioned, while ESP-IDF stays outside
the repo and can be reinstalled as needed.

---

## 2. Host Environment Overview

### 2.1 Host OS
- Windows 11
- WSL2 enabled

### 2.2 Linux Distribution
- Ubuntu 22.04 LTS (single instance)
- Running under WSL2

Verify:

    wsl -l -v

Expected:

    Ubuntu-22.04    Running    2

---

## 3. Base Linux Toolchain Installation

### 3.1 Update System Packages

    sudo apt update
    sudo apt upgrade -y

---

### 3.2 Core Build Tools

Required for Espruino build system and ESP-IDF:

    sudo apt install -y \
      build-essential \
      gcc \
      g++ \
      make \
      cmake \
      ninja-build \
      pkg-config \
      git \
      curl \
      unzip \
      zip \
      tar \
      xz-utils \
      libusb-1.0-0-dev

---

### 3.3 Python (System)

ESP-IDF v4.4.x requires Python 3.8–3.11.

Ubuntu 22.04 provides Python 3.10 (validated):

    python3 --version

Expected:

    Python 3.10.x

Install supporting packages:

    sudo apt install -y \
      python3 \
      python3-pip \
      python3-venv \
      python3-setuptools \
      python3-wheel

---

## 4. Node.js Toolchain (for Espruino Build Scripts)

Espruino requires Node.js for build tooling.

### 4.1 Install NVM (Node Version Manager)

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

Reload shell:

    source ~/.bashrc

Verify:

    nvm --version

---

### 4.2 Install Node.js (LTS)

Validated version used in this thread:

    nvm install 24
    nvm use 24
    nvm alias default 24

Verify:

    node --version
    npm --version

Expected:

    node v24.x
    npm 11.x

---

## 5. Directory Layout (Canonical)

A clean separation was used:

    ~/dev/
      ├── esp/          # ESP-IDF installations & scripts
      └── espruino/     # Espruino source trees

Create:

    mkdir -p ~/dev/esp ~/dev/espruino

---

## 6. ESP-IDF Installation (Parallel Versions)

Both IDF v4.4.8 (required today) and v5.x (future work) were installed **side-by-side**.

---

### 6.1 ESP-IDF v4.4.8 (Primary / Validated)

Clone:

    cd ~/dev/esp
    git clone -b v4.4.8 --recursive https://github.com/espressif/esp-idf.git esp-idf-v4.4.8

If submodules fail, retry:

    cd esp-idf-v4.4.8
    git submodule update --init --recursive

---

### 6.2 Install ESP-IDF v4.4.8 Tools

    cd ~/dev/esp/esp-idf-v4.4.8
    ./install.sh

This installs:
- Python virtual environment
- esptool
- CMake helpers
- Xtensa / RISC-V toolchains

---

### 6.3 ESP-IDF v4.4.8 Activation Script (Custom)

Activation helpers are tracked in this repo under `scripts/`.
Ensure they are executable and source them when needed:

    chmod +x <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh
    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh

---

### 6.4 ESP-IDF v5.x (Installed but Not Active)

Installed for future work:

    cd ~/dev/esp
    git clone -b v5.2.2 --recursive https://github.com/espressif/esp-idf.git esp-idf-v5.2.2
    cd esp-idf-v5.2.2
    ./install.sh

Activation script (optional, not used in this thread):

    <TOOLCHAIN_ROOT>/scripts/idf5.2.2.sh

Important:
- IDF versions are **never switched implicitly**
- Activation is explicit per shell

---
## 7. Decision Record: ESP-IDF VS Code Extension

### 7.1 Decision

The **ESP-IDF VS Code extension is intentionally not used** in the baseline workflow.

---

### 7.2 Rationale

Observed issues when attempting to use the extension:

- Implicit ESP-IDF activation overrides manual version selection
- IDF version conflicts when multiple versions are installed
- Terminal crashes during flashing and JTAG operations
- No tangible benefit for Espruino’s Makefile-driven build

The Espruino workflow:
- Does not use `idf.py build`
- Does not benefit from CMake project management
- Requires strict IDF version control

---

### 7.3 Current Guidance

- Use **plain VS Code + WSL**
- Use **manual IDF activation scripts**
- Use **esptool directly** for flashing

The VS Code ESP-IDF extension may be reconsidered **later**, once:
- IDF5 migration begins
- Native Linux (non-WSL) JTAG stability is proven

---

## 8. Espruino Source Tree Setup

### 8.1 Repository Management

A **bare repository + worktrees** model was used.

Bare repo:

    ~/dev/espruino/Espruino-admin.git

Worktrees:

    ~/dev/espruino/Espruino-master
    ~/dev/espruino/Espruino-fix-2649

### 8.2 Why This Model Was Used

A bare repository with worktrees was deliberately chosen to support:

- Clean tracking of upstream `master`
- Parallel experimental branches
- Safe recovery during disruptive environment changes
- Independent build outputs per branch

### 8.3 Practical Benefits Observed

- Ability to reset master cleanly after toolchain changes
- Isolation of Fix-for-#2649 during heavy ESP-IDF work
- No need to reclone or rebootstrap dependencies

This model is **recommended for all non-trivial Espruino development**.
---

### 8.4 Espruino Build Dependencies (Node)

From any Espruino worktree root:

    npm install

This installs:
- Closure compiler helpers
- JS build utilities
- Compression tools

---

## 9. Validated Build Command (ESP32-C3 / IDF4)

### 9.1 Environment Setup

    source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh
    cd ~/dev/espruino/Espruino-fix-2649

---

### 9.2 Build

    make BOARD=ESP32C3_IDF4

Expected result:
- build artifacts under `bin/build/`
- packaged archive under `bin/espruino_*.tgz`

---

## 10. Flashing Toolchain (esptool.py)

Flashing was performed **outside idf.py**, using esptool directly.

### 10.1 Flash Script Location

    <TOOLCHAIN_ROOT>/scripts/flash-espruino-c3.sh

This script uses:
- esptool from IDF v4.4.8
- build artifacts from `bin/build/`

### 10.2 Invocation

    <TOOLCHAIN_ROOT>/scripts/flash-espruino-c3.sh /dev/ttyUSB0 ~/dev/espruino/Espruino-fix-2649

This approach:
- Avoids CMake target confusion
- Avoids idf.py crashes under WSL
- Matches Espruino build output exactly

---

## 11. Validation Summary

This toolchain successfully supports:

- Espruino build (ESP32-C3)
- esptool flashing under WSL
- Parallel ESP-IDF installs
- Clean environment activation
- Reproducible workflows

Known limitations (documented elsewhere):
- USB-JTAG instability under WSL
- udev limitations

---

## 12. Status

- Toolchain: **validated**
- Build workflow: **validated**
- Flash workflow: **validated**
- Monitoring: pending finalisation

This document represents the **baseline reference toolchain** for ongoing Espruino development in this project.

---

## 13. Appendix - VS Code Workspace and Shortcut

This project uses a [multi-root VS Code workspace](https://code.visualstudio.com/docs/editing/workspaces/workspaces) so the toolchain repo and all
Espruino worktrees are open side-by-side in one VScode window.

### 13.1 Workspace Architecture

VSCode Workspace file contents:

    <TOOLCHAIN_ROOT>/../espruino.code-workspace

``` powershell
{
  "folders": [
    {
      "path": "/home/simon/dev/espruino/espruino-SGA-toolchain"
    },
    {
      "path": "/home/simon/dev/espruino/Espruino-fix-2609"
    },
    {
      "path": "/home/simon/dev/espruino/Espruino-SGA-Sandbox"
    },
    {
      "path": "/home/simon/dev/espruino/Espruino-fix-2649"
    },
    {
      "path": "/home/simon/dev/espruino/Espruino-master"
    }
  ],
  "settings": {}
}
```
Add additional paths in the file , to include further branches in the VScode environment.

This keeps the toolchain repo separate from the Espruino worktrees, while
letting Source Control show each repo in a single VS Code instance.

### 13.2 Windows Shortcut (Open in WSL)

Create a desktop shortcut that launches the workspace directly in WSL:

Target:

    "C:\Users\simon\AppData\Local\Programs\Microsoft VS Code\Code.exe" --remote wsl+Ubuntu-22.04 "/home/simon/dev/espruino/espruino.code-workspace"

Notes:
- Requires the "Remote - WSL" extension in VS Code.
- If the workspace paths change, update the shortcut target accordingly.

---

## 14. Appendix - Quick Reference

This section captures the Windows PowerShell commands used to manage WSL
during installation and recovery.

### 14.1 WSL PowerShell Commands

List installed distributions with status and WSL version:

```powershell
wsl -l -v
```

List installed distributions (verbose listing):

```powershell
wsl --list --verbose
```

Start the default WSL distribution:

```powershell
wsl
```

Start a specific distribution (Ubuntu 22.04):

```powershell
wsl -d Ubuntu-22.04
```

Shut down all WSL instances:

```powershell
wsl --shutdown
```

Terminate a specific distribution:

```powershell
wsl -t Ubuntu-22.04
```
