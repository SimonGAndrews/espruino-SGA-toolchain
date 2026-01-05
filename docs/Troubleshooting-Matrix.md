# Espruino Toolchain & WSL Troubleshooting Matrix  
## Symptom → Cause → Diagnosis → Resolution

---

## 1. Purpose

This matrix consolidates **all failure modes encountered and resolved** during the Espruino toolchain setup, build, USB attachment, and flashing workflow under:

- Windows 11
- WSL2 (Ubuntu 22.04)
- ESP-IDF v4.4.8
- ESP32-C3 hardware

It is intended as a **fast diagnostic reference** when something breaks.

---

## 2. Environment & Shell Issues

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| VS Code terminal closes immediately | Broken shell startup file | `bash -lic 'echo ok'` | Fix syntax errors in `~/.profile` or `~/.bashrc` |
| `bash: syntax error near unexpected token fi` | Extra `fi` in profile | `nl -ba ~/.profile` | Remove stray `fi`, rebuild file cleanly |
| `exit code: 1` when opening terminal | Shell returns non-zero on login | `bash --noprofile --norc` | Remove `exit`, `return`, or `set -e` from login scripts |
| `idf.py: command not found` | IDF not sourced | `echo $IDF_PATH` | `source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh` |

---

## 3. ESP-IDF Setup Problems

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| `idf.py --version` fails | IDF not installed or exported | `ls $IDF_PATH` | Re-run `./install.sh` |
| Wrong IDF version used | Multiple IDFs installed | `idf.py --version` | Explicitly source correct script |
| `MultiCommand deprecated` warning | Expected (Click warning) | Seen on startup | Ignore (harmless) |
| CMake target mismatch (`esp32` vs `esp32c3`) | Reusing build dir | Error mentions sdkconfig | Ignore when using esptool; or run `idf.py fullclean` |

---

## 4. Git / Build Directory Issues

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| `CMakeLists.txt not found` | Running from wrong directory | `pwd` | Use `targets/esp32/IDF4` or repo root |
| Build succeeds but flash fails | Wrong working directory | `ls bin/build` | Flash using absolute paths |
| `bootloader.bin not found` | Script assumes wrong layout | `find . -name bootloader.bin` | Fix flash script paths |

---

## 5. USB Device Not Visible in WSL

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| Device visible in Windows only | Not attached to WSL | `usbipd list` | `usbipd attach --busid X-Y --wsl` |
| Device detaches repeatedly | Auto-attach instability | dmesg spam | Avoid `--auto-attach` |
| `/dev/bus/usb` missing | usbipd not active | `ls /dev/bus/usb` | Reattach device |
| `vhci_hcd` spam in dmesg | JTAG instability | `dmesg | tail` | Switch to USB-Serial |

---

## 6. Serial Port Issues

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| `/dev/ttyUSB0` missing | Driver not bound | `lsusb`, `dmesg` | Use CH340 / CP210x |
| `/dev/ttyUSB0 exists but unreadable` | Permissions | `ls -l /dev/ttyUSB0` | `sudo chgrp dialout /dev/ttyUSB0` |
| `idf.py: port not readable` | User not in group | `groups` | Re-login or manual chmod |
| `udevadm reload` fails | No udev in WSL | Error output | Ignore, use manual chmod |

---

## 7. USB-JTAG Specific Failures (ESP32-C3 / S3)

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| USB-JTAG appears in lsusb only | Composite device | `lsusb -v` | Not a tty device |
| No `/dev/ttyACM*` created | CDC not exposed | dmesg | Use external USB-Serial |
| idf.py crashes terminal | JTAG interaction bug | Terminal exit | Avoid JTAG in WSL |
| Flash hangs at connect | Boot/JTAG conflict | esptool timeout | Hold BOOT + RESET |

---

## 8. Flashing Failures (esptool)

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| `No such file or directory: bootloader.bin` | Wrong path | `find bin -name bootloader.bin` | Fix flash script |
| Flash starts then resets | Wrong baud / reset | esptool output | Lower baud or manual reset |
| `Chip not responding` | Boot mode wrong | esptool retry | Hold BOOT during connect |
| Flash succeeds but no output | Console mismatch | Serial monitor | Check baud (115200) |

---

## 9. idf.py Usage Pitfalls

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| `idf.py flash` crashes | Wrong project root | CMake error | Use esptool directly |
| `No such option: -v` | idf.py v4 syntax | Help output | Remove `-v` |
| Flash ignores build | Cache confusion | Target mismatch | Avoid idf.py |

---

## 10. VS Code Integration Issues

| Symptom | Likely Cause | How to Diagnose | Resolution |
|-------|-------------|----------------|------------|
| Terminal closes on flash | Child process crash | VS Code log | Run flash externally |
| WSL disconnects | USB reset | Windows log | Use PowerShell for attach |
| Plugin complicates setup | IDF mismatch | Conflicting env | Avoid plugin initially |

---

## 11. Known-Good Recovery Steps

When things are badly broken:

1. Close VS Code
2. In PowerShell:
   - `usbipd detach --busid X-Y`
   - Reattach device
3. Open fresh WSL terminal
4. `source <TOOLCHAIN_ROOT>/scripts/idf4.4.8.sh`
5. Flash via esptool script
6. Monitor via `picocom`

---
## 12. Shell Stability & Recovery (Critical for WSL + VS Code)

### 12.1 Background

During setup, multiple **VS Code WSL terminal crashes** occurred with exit codes `1` and `2`.  
These were traced to **syntax errors and unsafe logic in login shell startup files**.

This is a **high-risk area in WSL**, because:
- VS Code always launches *login shells*
- Any non-zero exit terminates the terminal
- ESP-IDF scripts use `set -e` internally, which amplifies errors

---

### 12.2 Known-Good Diagnostic Commands

Use these to isolate shell issues safely:

    bash --noprofile --norc
    bash -lic 'echo login-ok'
    nl -ba ~/.profile
    nl -ba ~/.bashrc

If `bash -lic` fails, **VS Code terminals will crash**.

---

### 12.3 Minimal Safe ~/.profile (Validated)

The following structure was validated as safe:

    # ~/.profile

    # Load bashrc for interactive shells
    if [ -n "$BASH_VERSION" ]; then
      if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
      fi
    fi

    # Local user binaries
    if [ -d "$HOME/bin" ]; then
      PATH="$HOME/bin:$PATH"
    fi

    if [ -d "$HOME/.local/bin" ]; then
      PATH="$HOME/.local/bin:$PATH"
    fi

---

### 12.4 Explicit Warnings

Do **NOT**:
- Put `source esp-idf/export.sh` in `.profile` or `.bashrc`
- Use `set -e` in login scripts
- Call `exit` or `return` in `.profile`

ESP-IDF activation **must be manual and explicit** per shell.

---

## 13. Final Guidance

- Prefer **USB-Serial over USB-JTAG** under WSL
- Avoid auto-attach for ESP devices
- Keep IDF activation explicit
- Use esptool directly for flashing
- Treat idf.py as optional tooling

This matrix represents **field-tested resolutions**, not theoretical fixes.
