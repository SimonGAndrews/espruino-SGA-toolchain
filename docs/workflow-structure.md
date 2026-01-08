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

* Avoids ESP-IDF project generation and utilises Espruino make
* Includes different ESP-IDF version setup in the toolchain
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

See also the comments in the script source for optional usage patterns

---

## 5. Espruino Build Process

### 5.1 Build Location

All builds are run from the Espruino repository root:

    ~/dev/espruino/Espruino-fix-2649

Builds must not be run from:
* targets/
* bin/
* bin/build/

### 5.2 Establishing build prerequisites

Espruino provides a provisioning helper:

    source scripts/provision.sh {BOARD}
	eg source ./scripts/provision.sh ESP32C3_IDF4

which sets up the depencencies necessary for a given board's build in Espruino. It Sets up toolchain and libraries for build targets, installing them if missing.  It also sets env vars for builds.

However, this toolchain does not rely on this provisioning script , for ESP-IDF builds, because ESP-IDF is installed/set-up separately and enabled via `scripts/idf4.4.8.sh` as above. 

The provisioning helper remains the upstream Espruino mechanism for setting up non ESP-IDF board dependencies (including the original ESP32).  The use of this Espruino provisioning is compatible here, but it will download and maintain its own/another ESP-IDF/toolchain copy inside the Espruino
worktree for the ESP-IDF boards. 

### 5.3 Build Command

The authoritative Espruino build command is:

    make BOARD=ESP32C3_IDF4

or When switching boards or ESP-IDF versions, run a clean build first to avoid stale outputs:

    make clean
    make BOARD=ESP32C3_IDF4

This command executes the main Espruino Makefile for the specific board.  It :
* Selects the correct ESP-IDF integration: 
  - BOARD maps to ESP32C3_IDF4 makefiles and the ESP-IDF v4 toolchain paths. (See Appendix A)
* Generates sdkconfig, partition tables, and linker scripts: 
    - the ESP‑IDF tools (run by the Espruino build) auto‑create these config and layout files inside the build folder so you don’t have to make them by hand.
* Invokes ESP‑IDF internally as required: 
    - the Espruino make files call ESP‑IDF’s build system (idf.py) for you; you never have to run idf.py yourself.
* Produces flash-ready binaries 
    - the build creates the ELF, then uses esptool/elf2image to emit bootloader and app BINs.

See Appendix 2 for the ESP32-C3 make targets and variables used by this build.

No direct use of idf.py build is required or recommended.

Debug and release options (Makefile flags):
- `DEBUG=1` adds debug symbols (`-g`) and keeps debug-friendly settings.
- `RELEASE=1` forces release-style compile (no asserts, etc).

Examples:

    DEBUG=1 make BOARD=ESP32C3_IDF4
    RELEASE=1 make BOARD=ESP32C3_IDF4

### 5.4 Build Outputs

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

---

## Appendix A - Makefile Trace Summary (Board to ESP-IDF Config)

Exact chain in the makefile scripts, with file/line refs:

Board selects family/part
- `boards/ESP32C3_IDF4.py` (lines 82-85) sets `chip['part']="ESP32C3"` and `chip['family']="ESP32_IDF4"`.

Makefile pulls those values into the build
- `Makefile` (lines 195-197) runs `get_makefile_decls.py $(BOARD)` and includes `CURRENT_BOARD.make`.
- `scripts/get_makefile_decls.py` (lines 47-52) prints `FAMILY=<chip family>` and `CHIP=<chip part>` into that file.

Family makefile is then included
- `Makefile` (lines 721-722) includes `make/family/$(FAMILY).make`, so for this board it includes `make/family/ESP32_IDF4.make`.
- `make/family/ESP32_IDF4.make` (line 5) sets `ESP32_IDF4=1`.

Target makefile is selected based on ESP32_IDF4
- `Makefile` (lines 894-895) includes `make/targets/ESP32_IDF4.make` when `ESP32_IDF4` is defined.

IDF v4 integration details
- `make/targets/ESP32_IDF4.make` (line 38) writes `-DESP_IDF_VERSION_MAJOR=4` into the generated CMake file.
- `make/targets/ESP32_IDF4.make` (lines 54-56) copies files from `targets/esp32/IDF4/` (`sdkconfig`, `partitions.csv`, `CMakeLists.txt`).

The chain in one line:
- `boards/ESP32C3_IDF4.py` -> `scripts/get_makefile_decls.py` -> `Makefile` includes -> `make/family/ESP32_IDF4.make` -> `make/targets/ESP32_IDF4.make`.

Toolchain paths note:
- The makefiles assume the ESP-IDF v4 environment is already active (from `export.sh`/`IDF_PATH`) so `idf.py` and tools are on `PATH`. The version tie-in is via the `ESP32_IDF4` family and `targets/esp32/IDF4/` configs.

---

## Appendix 2 - Espruino Makefile Targets for ESP32-C3

This appendix documents the ESP32-C3-related targets and variables in
`make/targets/ESP32_IDF4.make`, with code excerpts and short explanations.

Overall workflow:
1. Generate `CMakeLists.txt` with `$(CMAKEFILE)`.
2. Build the firmware binary with `$(PROJ_NAME).bin`.
3. Package the firmware with `$(ESP_ZIP)`.
4. Flash the firmware with `flash`, or flash and monitor with `flashmonitor`.

### 1. Chip Selection and Defaults

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
ESP_ZIP     = $(PROJ_NAME).tgz

CMAKEFILE = $(BINDIR)/main/CMakeLists.txt
# 'gen' has a relative path - get rid of it and add it manually
INCLUDE_WITHOUT_GEN = $(subst -Igen,,$(INCLUDE)) -I$(ROOT)/gen

ifeq ($(CHIP),ESP32C3)
	SDKCONFIG = sdkconfig_c3
	FMW_BIN_NAME = espruino-esp32c3
	PORT ?= /dev/ttyACM0
else
	ifeq ($(CHIP),ESP32)
		SDKCONFIG = sdkconfig
		FMW_BIN_NAME = espruino-esp32
		PORT ?= /dev/ttyUSB0
	else
		ifeq ($(CHIP),ESP32S3)
			SDKCONFIG = sdkconfig_s3
			FMW_BIN_NAME = espruino-esp32s3
			PORT ?= /dev/ttyUSB0
		else
			$(error Unknown ESP32 chip)
		endif
	endif
endif
```

Explanation:
- Configures build settings based on the target ESP32 chip:
  - ESP32-C3: uses `sdkconfig_c3`, binary name `espruino-esp32c3`, and port `/dev/ttyACM0`.
  - ESP32: uses `sdkconfig`, binary name `espruino-esp32`, and port `/dev/ttyUSB0`.
  - ESP32-S3: uses `sdkconfig_s3`, binary name `espruino-esp32s3`, and port `/dev/ttyUSB0`.
- Raises an error for unknown chips.

Key variables:
- `ESP_ZIP`: name of the compressed firmware archive.
- `CMAKEFILE`: path to the `CMakeLists.txt` file being generated.
- `INCLUDE_WITHOUT_GEN`: include directories with adjustments for the build.
- `SDKCONFIG`: the correct `sdkconfig` file for the target chip (ESP32-C3, ESP32, or ESP32-S3).
- `FMW_BIN_NAME`: firmware binary name based on the target chip.
- `PORT`: serial port for flashing the firmware (defaults to `/dev/ttyACM0` for ESP32-C3).

### 2. Generate CMakeLists.txt ($(CMAKEFILE))

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
$(CMAKEFILE):
	@mkdir -p $(BINDIR)/main # create directory if it doesn't exist
	@echo "MAKE CMAKEFILE"
	@echo "$(INCLUDE_WITHOUT_GEN)"
	@echo "idf_component_register(" > $(CMAKEFILE)
	@echo "						 SRCS" >> $(CMAKEFILE)
	@echo "						$(patsubst %,\"$(ROOT)/%\"\n						,$(SOURCES))" >> $(CMAKEFILE)
	@echo "						 INCLUDE_DIRS" >> $(CMAKEFILE)
	@echo "						$(patsubst -I%,\"%/\"\n						,$(INCLUDE_WITHOUT_GEN))" >> $(CMAKEFILE)
	@echo "						 )" >> $(CMAKEFILE)
	@echo "" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_TARGET} PUBLIC -DESP_IDF_VERSION_MAJOR=4)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_TARGET} PUBLIC $(DEFINES))" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_TARGET} PUBLIC -Og -fno-strict-aliasing -ffunction-sections -fdata-sections -fstrict-volatile-bitfields -fgnu89-inline  -nostdlib -MMD -MP -Wno-enum-compare)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-pointer-sign)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-implicit-int)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-maybe-uninitialized)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-return-type)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-switch)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-unused-variable)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-unused-function)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-unused-but-set-variable)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-cast-function-type)" >> $(CMAKEFILE)
	@echo "target_compile_options($$""{COMPONENT_LIB} PRIVATE -Wno-format)" >> $(CMAKEFILE)
```

Explanation:
- Creates the `$(BINDIR)/main` directory if it does not exist.
- Generates the `CMakeLists.txt` file required by ESP-IDF.
- Registers source files (`SRCS`) and include directories (`INCLUDE_DIRS`) for the project.
- Defines compilation options, including optimizations and ignored warnings.
- Note: `INCLUDE_WITHOUT_GEN` strips `-Igen` so the generated include path can be added explicitly.

This ensures the ESP-IDF build environment is prepared before compiling.

### 3. Build Firmware Binary ($(PROJ_NAME).bin)

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
$(PROJ_NAME).bin: $(CMAKEFILE) $(PLATFORM_CONFIG_FILE) $(PININFOFILE).h $(PININFOFILE).c $(WRAPPERFILE)
	$(Q)cp ${ROOT}/targets/esp32/IDF4/${SDKCONFIG} $(BINDIR)/sdkconfig
	$(Q)cp ${ROOT}/targets/esp32/IDF4/CMakeLists.txt $(BINDIR)
	$(Q)cp ${ROOT}/targets/esp32/IDF4/partitions.csv $(BINDIR)
	cd $(BINDIR) && idf.py build
	$(Q)cp $(BINDIR)/build/espruino.bin $(PROJ_NAME).bin
```

Explanation:
- Builds the Espruino firmware binary.
- Copies the `sdkconfig`, `CMakeLists.txt`, and `partitions.csv` files into the build directory.
- Runs the ESP-IDF build process (`idf.py build`).
- Copies the generated binary (`espruino.bin`) to the project output path as `$(PROJ_NAME).bin`.
- Note: ESP-IDF outputs into `$(BINDIR)/build/` and this target copies it to the Espruino naming convention.

Summary of dependencies:
- `$(CMAKEFILE)`: ESP-IDF project glue (CMakeLists.txt).
- `$(PLATFORM_CONFIG_FILE)`: platform-specific configuration.
- `$(PININFOFILE).h/.c`: pin mappings and peripheral setup.
- `$(WRAPPERFILE)`: generated JS-to-C bindings for Espruino APIs.

### 4. Package Firmware Archive ($(ESP_ZIP))

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
$(ESP_ZIP): $(PROJ_NAME).bin
	$(Q)rm -rf $(PROJ_NAME)
	$(Q)mkdir -p $(PROJ_NAME)
	$(Q)cp $(PROJ_NAME).bin $(PROJ_NAME)/$(FMW_BIN_NAME).bin
	$(Q)cp $(BINDIR)/build/partition_table/partition-table.bin $(PROJ_NAME)/partition-table.bin
	$(Q)cp $(BINDIR)/build/bootloader/bootloader.bin $(PROJ_NAME)/bootloader.bin
	$(Q)cp targets/esp32/README_flash.txt $(PROJ_NAME)
	$(Q)cp targets/esp32/README_flash_C3.txt $(PROJ_NAME)
	$(Q)cp targets/esp32/README_flash_S3.txt $(PROJ_NAME)
	$(Q)$(TAR) -zcf $(ESP_ZIP) $(PROJ_NAME) --transform='s/$(BINDIR)\///g'
	@echo "Created $(ESP_ZIP)"
```

Explanation:
- Packages the built firmware into a `.tgz` archive.
- Includes the firmware binary (`$(PROJ_NAME).bin` renamed to `$(FMW_BIN_NAME).bin`).
- Includes the partition table and bootloader binaries.
- Includes flashing instructions (`README_flash*.txt`).
- Note: `$(FMW_BIN_NAME)` varies by chip (ESP32C3/ESP32S3), and `--transform` removes `$(BINDIR)` from archive paths.

This bundles all files required for deployment into a single archive.

### 5. Flash Firmware (flash)

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
flash: $(PROJ_NAME).bin
	cd $(BINDIR) && idf.py flash -p $(PORT)
```

Explanation:
- Flashes the firmware binary to the ESP32-C3 device.
- Uses the ESP-IDF `idf.py flash` command with the selected serial port (`$(PORT)`).
- Note: `$(PORT)` has defaults set in the ESP32_IDF4 makefile based on chip.
- Note: `idf.py flash` uses the bootloader and partition outputs from `$(BINDIR)/build/`.

### 6. Flash and Monitor (flashmonitor)

Code (from `make/targets/ESP32_IDF4.make`):

```makefile
flashmonitor: $(PROJ_NAME).bin
	cd $(BINDIR) && idf.py flash -p $(PORT)
	cd $(BINDIR) && idf.py monitor -p $(PORT)
```

Explanation:
- Combines the `flash` target with `idf.py monitor`.
- Flashes the firmware and starts a terminal interface to view the device output.
- Useful for debugging, as it allows immediate feedback from the device.
- Note: exit the monitor with Ctrl-].
