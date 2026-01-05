# ADDENDUM — Environment Stability, Tooling Decisions & Final Clarifications

This addendum captures **important implementation details and decisions** that were exercised during setup and debugging, but which benefit from being stated explicitly for long-term maintainability and handover.

These sections should be merged into the existing reference documents as noted.

---

## A. Shell Stability & Recovery (Critical for WSL + VS Code)
**Suggested placement:**  
Toolchain Setup Reference → after “Host Environment Overview”  
or  
Troubleshooting Matrix → first section

### A.1 Background

During setup, multiple **VS Code WSL terminal crashes** occurred with exit codes `1` and `2`.  
These were traced to **syntax errors and unsafe logic in login shell startup files**.

This is a **high-risk area in WSL**, because:
- VS Code always launches *login shells*
- Any non-zero exit terminates the terminal
- ESP-IDF scripts use `set -e` internally, which amplifies errors

---

### A.2 Known-Good Diagnostic Commands

Use these to isolate shell issues safely:

    bash --noprofile --norc
    bash -lic 'echo login-ok'
    nl -ba ~/.profile
    nl -ba ~/.bashrc

If `bash -lic` fails, **VS Code terminals will crash**.

---

### A.3 Minimal Safe ~/.profile (Validated)

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

### A.4 Explicit Warnings

Do **NOT**:
- Put `source esp-idf/export.sh` in `.profile` or `.bashrc`
- Use `set -e` in login scripts
- Call `exit` or `return` in `.profile`

ESP-IDF activation **must be manual and explicit** per shell.

---

## B. Decision Record: ESP-IDF VS Code Extension
**Suggested placement:**  
Toolchain Setup Reference → after ESP-IDF Installation

### B.1 Decision

The **ESP-IDF VS Code extension is intentionally not used** in the baseline workflow.

---

### B.2 Rationale

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

### B.3 Current Guidance

- Use **plain VS Code + WSL**
- Use **manual IDF activation scripts**
- Use **esptool directly** for flashing

The VS Code ESP-IDF extension may be reconsidered **later**, once:
- IDF5 migration begins
- Native Linux (non-WSL) JTAG stability is proven

---

## C. Serial Monitor Status (Explicitly Deferred)
**Suggested placement:**  
Main README → Workflow Status  
or  
USB / WSL Reference → after Flashing section

### C.1 Status

Serial monitoring is **intentionally deferred**.

Build and flash workflows are validated and stable; monitoring is still under evaluation due to:

- USB-JTAG instability under WSL
- CDC device enumeration inconsistency
- VS Code terminal sensitivity during serial attach

---

### C.2 Current Position

- `picocom` works in principle with USB-Serial adapters
- USB-JTAG CDC is unreliable under WSL
- Final REPL workflow will be documented once stability is confirmed

This is a **known open item**, not an omission.

---

## D. Git Bare Repository + Worktrees (Rationale)
**Suggested placement:**  
Toolchain Setup Reference → Espruino Source Tree Setup

### D.1 Why This Model Was Used

A bare repository with worktrees was deliberately chosen to support:

- Clean tracking of upstream `master`
- Parallel experimental branches
- Safe recovery during disruptive environment changes
- Independent build outputs per branch

---

### D.2 Practical Benefits Observed

- Ability to reset master cleanly after toolchain changes
- Isolation of Fix-for-#2649 during heavy ESP-IDF work
- No need to reclone or rebootstrap dependencies

This model is **recommended for all non-trivial Espruino development**.

---

## E. Known-Good Versions (Baseline Lock-In)
**Suggested placement:**  
Toolchain Setup Reference → Summary or Validation section

The following versions were validated together:

| Component        | Version            | Status     |
|------------------|--------------------|------------|
| Windows          | 11                 | validated  |
| WSL              | 2                  | required   |
| Ubuntu           | 22.04 LTS          | validated  |
| Python           | 3.10.x             | required   |
| Node.js          | 24.x (LTS)         | validated  |
| npm              | 11.x               | validated  |
| ESP-IDF          | 4.4.8              | required   |
| ESP-IDF (future) | 5.2.2              | installed  |
| usbipd-win       | 5.x                | validated  |
| esptool          | from IDF 4.4.8     | validated  |
| USB-Serial       | CH340 / CP210x     | validated  |

Deviation from these versions should be treated as **intentional change** and tested accordingly.

---

## F. Final Clarification

All critical steps required to:

- build Espruino
- flash reliably under WSL
- recover from failures
- repeat the workflow safely

are now **explicitly documented**.

Remaining work (serial monitor refinement, IDF5 migration, JTAG debugging) is **deliberately deferred**, not missing.

This addendum completes the environment and workflow documentation set.
