# WSL USB Setup Reference  
## Supporting Espruino Development (ESP32 / ESP32-C3 / ESP32-S3)

---

## 1. Purpose & Scope

This document describes a **known-good approach to USB device setup, usage, and troubleshooting in WSL2** specifically to support **Espruino development workflows**.

It reflects practical experience gained while building and flashing Espruino on ESP32-C3 hardware under:

- Windows 11
- WSL2 (Ubuntu 22.04)
- ESP-IDF v4.4.8
- usbipd-win

The focus is on:
- USB-Serial devices (CH340, CP210x, FTDI)
- ESP32 USB-JTAG / Serial composite devices
- Stability considerations under WSL
- Proven workarounds for flashing and development

This document complements the main workflow documentation located at:

    <TOOLCHAIN_ROOT>/docs

---

## 2. Architectural Overview (WSL USB Model)

WSL2 does **not** have direct access to host USB devices.

Instead:
- USB devices are managed on Windows
- Devices are forwarded into WSL using `usbipd-win`
- A virtual USB host controller (`vhci_hcd`) appears inside WSL

Key implications:
- Device attach/detach is explicit
- udev is limited or absent
- Permissions may need manual adjustment
- USB-JTAG devices may be unstable under WSL

---

## 3. Required Windows Components

### 3.1 usbipd-win

usbipd-win must be installed on Windows.

Verify installation:

    usbipd --version

List devices:

    usbipd list

Typical output:

    BUSID  VID:PID    DEVICE                                   STATE
    3-3    303a:1001  USB JTAG/serial debug unit               Not shared
    3-4    1a86:7523  USB-SERIAL CH340 (COM4)                  Not shared

---

## 4. Attaching USB Devices to WSL

### 4.1 Identify the Device (Windows PowerShell)

List all USB devices:

    usbipd list

Identify:
- BUSID (e.g. 3-4)
- VID:PID
- Device description

---

### 4.2 Attach a Device to WSL

Attach a device (single attach):

    usbipd attach --busid 3-4 --wsl

Attach with auto-reattach (use cautiously):

    usbipd attach --auto-attach --busid 3-4 --wsl

Notes:
- Administrator privileges are required
- Auto-attach may cause instability with JTAG devices

---

### 4.3 Detach a Device

If needed:

    usbipd detach --busid 3-4

---

## 5. Verifying USB Devices Inside WSL

### 5.1 List USB Devices

Inside WSL:

    lsusb

Example output:

    Bus 001 Device 006: ID 1a86:7523 QinHeng Electronics CH340 serial converter
    Bus 001 Device 005: ID 303a:1001 Espressif USB JTAG/serial debug unit

---

### 5.2 Check Kernel Messages

    dmesg | tail -n 50

Look for:
- USB device attach
- Serial driver binding (e.g. ch341, cp210x)
- tty device assignment

---

### 5.3 Check Serial Device Nodes

    ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null

Typical result for CH340:

    /dev/ttyUSB0

USB-JTAG devices may **not** create tty nodes reliably.

---

## 6. Serial Port Permissions (WSL Reality)

WSL may not run a full `udevd`. As a result:

- udev rules may not reload
- Serial permissions may default to root-only

### 6.1 Check Permissions

    ls -l /dev/ttyUSB0

Expected:

    crw-rw---- root dialout ...

### 6.2 Fix Permissions Manually

    sudo chgrp dialout /dev/ttyUSB0
    sudo chmod 660 /dev/ttyUSB0

### 6.3 Verify Group Membership

    groups | tr ' ' '\n' | grep -x dialout

---

## 7. Common Debugging Commands (WSL Side)

### 7.1 USB Bus Presence

    ls -l /dev/bus/usb

### 7.2 Kernel USB Stack

    lsmod | grep usb

    lsmod | grep vhci

### 7.3 Device Re-enumeration

Unplug/replug device, then:

    dmesg | tail -n 80

---

## 8. Known Failure Modes & Diagnostics

### 8.1 Device Visible in Windows but Not in WSL

Checks:
- Device must be attached via usbipd
- Verify `usbipd list` shows state = Attached
- Reattach if necessary

---

### 8.2 Device Appears in lsusb but No /dev/ttyUSB*

Likely causes:
- USB-JTAG composite device
- Driver binding issues
- Serial interface not exposed

Workaround:
- Use external USB-Serial (CH340 / CP210x)
- Or ESP-PROG

---

### 8.3 Device Repeatedly Attaches/Detaches

Seen with:
- USB-JTAG interfaces
- Auto-attach mode
- Heavy traffic (OpenOCD, idf.py monitor)

Recommendation:
- Avoid auto-attach for JTAG
- Prefer manual attach
- Use stable USB-Serial for flashing

---

## 9. Proven Flashing Strategy Under WSL

### 9.1 Do Not Rely on USB-JTAG for Flashing

Experience shows:
- ESP32 USB-JTAG is unstable under WSL
- tty device may not appear
- esptool connection may fail mid-flash

### 9.2 Recommended Flashing Interfaces

Preferred:
- CH340 / CP210x USB-Serial
- ESP-PROG USB-Serial channel

Avoid (for flashing under WSL):
- Native ESP32 USB-JTAG interface

---

## 10. Appendix A – USB-JTAG Issues (ESP32-C3 / ESP32-S3)

### A.1 Symptoms Observed

- USB-JTAG device attaches in Windows
- Appears in lsusb in WSL
- No /dev/ttyACM* or /dev/ttyUSB* created
- Repeated connect/disconnect messages in dmesg
- idf.py / esptool unable to open port
- VS Code terminal crashes during JTAG operations

### A.2 Root Causes

- Composite USB device (JTAG + CDC)
- Partial driver support under vhci_hcd
- Timing-sensitive reset/boot sequences
- WSL USB virtualization limitations

### A.3 Workarounds (Validated)

1. **Use External USB-Serial for Flashing**
   - CH340, CP210x, FTDI
   - Stable /dev/ttyUSB0

2. **Use ESP-PROG**
   - USB-Serial for flashing
   - JTAG only when required
   - Prefer flashing via serial, not JTAG

3. **Avoid idf.py flash**
   - Use esptool.py directly
   - Matches Espruino build output
   - Avoids CMake/target confusion

4. **Separate Concerns**
   - Serial for flashing + REPL
   - JTAG only for debugging (future work)

### A.4 Recommended Practice (Espruino)

For ESP32-C3 / ESP32-S3 under WSL:

- Flash via USB-Serial
- Monitor via USB-Serial
- Defer USB-JTAG usage unless strictly required
- Expect better JTAG stability on native Linux

---

## 11. Summary

This document captures a **stable, experience-based USB strategy** for Espruino development under WSL:

- usbipd-win is required and effective
- USB-Serial is reliable
- USB-JTAG is fragile under WSL
- Direct esptool.py flashing is robust
- Manual permission fixes are normal

Used together with the main Espruino workflow README, this provides a complete and repeatable development environment.

---

Document status:
- USB-Serial workflow: validated
- Flashing via esptool.py: validated
- USB-JTAG under WSL: documented with workarounds
- Monitoring strategy: evolving
