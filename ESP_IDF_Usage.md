# ESP-IDF VS Code Extension - Usage Notes (Discussion Draft)

This document captures setup questions and guidance for ESP-IDF usage in the
Espruino toolchain workflow, with the goal of evaluating the VS Code ESP-IDF
extension as an incremental addition where it provides clear advantage.

## Q1. What folders are populated during setup and what is the purpose of each?

This answer separates the current baseline layout from the additional folders
that can be introduced when the VS Code ESP-IDF extension is enabled.

Baseline workflow (current repo guidance):

- `~/dev/esp/`:
  - Purpose: Host ESP-IDF installations and their tooling.
  - Contents:
    - `esp-idf-v4.4.8/`: Primary, validated ESP-IDF version used today.
    - `esp-idf-v5.2.2/`: Installed for future migration work, not used in this workflow.
  - Tool installs created by `./install.sh`:
    - By default, ESP-IDF installs shared tools under `~/.espressif/` (unless
      `IDF_TOOLS_PATH` is set). If `IDF_TOOLS_PATH` is overridden, tools can be
      placed elsewhere by policy.

- `~/dev/espruino/`:
  - Purpose: Espruino source trees (worktrees/branches) and build outputs.
  - Contents:
    - Espruino worktrees (e.g., `Espruino/`, `Espruino-fix/`), each with its
      own `build/` and board-specific outputs.

ESP-IDF VS Code extension (incremental additions):

- Project workspace adds or updates `.vscode/`:
  - Purpose: Editor configuration and extension settings.
  - Typical contents: `settings.json`, `launch.json`, `c_cpp_properties.json`.

- Extension-managed ESP-IDF/tooling locations:
  - Purpose: Store the ESP-IDF install and tools selected by the extension.
  - Common defaults (when using the extension installer):
    - `~/.espressif/`: Toolchains, Python environments, and caches.
    - An ESP-IDF repo directory chosen during setup (often under `~/esp/`).
  - Note: These can be configured to point at the existing `~/dev/esp/`
    installs to avoid duplication.

Notes:
- ESP-IDF activation remains explicit per shell via `scripts/idf4.4.8.sh` or
  `scripts/idf5.2.2.sh` unless the extension is configured to manage activation.
- The extension can provide value without taking over builds by focusing on
  IDE features (code navigation, IntelliSense, flashing/monitoring) while
  preserving the Makefile-driven workflow.

## Q2. What is the purpose of each prompt in the configure extension process?

Prompts from the ESP-IDF setup wizard (`ESP-IDF: Configure ESP-IDF Extension`)
and how they map to folders:

- Choose setup mode (Express):
  - Purpose: Use the guided installer flow; it either downloads ESP-IDF or
    discovers an existing install.
  - Folder impact: None directly.

- Select download server (Espressif or GitHub):
  - Purpose: Choose where ESP-IDF/tools downloads are pulled from.
  - Folder impact: None directly.

- Pick an ESP-IDF version or "Find ESP-IDF in your system":
  - Purpose: Either install a new ESP-IDF version or point to an existing one.
  - Folder impact: Sets `IDF_PATH`.
  - For this workflow: prefer "Find ESP-IDF in your system" and select
    `~/dev/esp/esp-idf-v4.4.8/` to avoid duplicate installs.

- Choose ESP-IDF Tools location (IDF_TOOLS_PATH):
  - Purpose: Where the toolchains, Python envs, and helper tools are installed.
  - Folder impact: Default is `~/.espressif/` on macOS/Linux unless overridden.
  - For this workflow: keep tools centralized (default is fine) and avoid
    pointing this at `~/dev/esp/esp-idf-v4.4.8/` because tools and IDF repo
    should not be the same directory.

- Select Python executable (macOS/Linux):
  - Purpose: Create the ESP-IDF Python virtual environment used by tools.
  - Folder impact: Creates/updates a Python env under `IDF_TOOLS_PATH`.

- Install:
  - Purpose: Executes downloads (if needed), installs tools, and creates
    the Python environment.
  - Folder impact: Writes into `IDF_TOOLS_PATH` and possibly the chosen
    ESP-IDF repo directory if a new version is downloaded.

Notes:
- ESP-IDF versions before v5 do not support spaces in configured paths.
- Keep `IDF_PATH` (ESP-IDF repo) and `IDF_TOOLS_PATH` (tools/venvs) separate.

## Q3. Can we use the ESP-IDF extension with ESP-IDF v4.4.8?

Yes. The extension supports using an existing ESP-IDF install, including v4.4.8.
Key constraints and fit for this workflow:

- Use "Find ESP-IDF in your system" and point to `~/dev/esp/esp-idf-v4.4.8/`.
- Avoid spaces in all configured paths (older IDF requirement).
- Keep `IDF_PATH` and `IDF_TOOLS_PATH` separate; tools typically live in
  `~/.espressif/`.
- Extension features that assume an ESP-IDF CMake project (e.g., `idf.py build`)
  are less applicable to the Espruino Makefile-driven flow, but IntelliSense,
  serial monitor, and flashing can still be useful if configured to use the
  existing toolchain and build outputs.

## Q4. What else in the setup should we consider to support our workflow?

Setup considerations to keep the extension additive (not disruptive) to the
existing Makefile-driven flow:

- Pin `IDF_PATH` to the validated install:
  - Ensure the extension points at `~/dev/esp/esp-idf-v4.4.8/` to avoid
    implicit version switches.

- Keep tools centralized and shared:
  - Use a single `IDF_TOOLS_PATH` (default `~/.espressif/`) so multiple
    worktrees reuse toolchains and Python envs.

- Avoid auto-managing builds:
  - Prefer extension features that don't require `idf.py build` (navigation,
    IntelliSense, monitor, flashing) to reduce divergence from the build
    system used by Espruino.

- Be explicit about serial ports and monitor:
  - Align the extension's monitor settings with the existing monitor workflow
    so the same device/baud settings are used.

- Keep paths space-free:
  - ESP-IDF v4.x does not support spaces in configured paths; keep all chosen
    locations space-free.

- Plan for potential conflicts:
  - The extension can modify `.vscode/` settings; keep these under review so
    workspace config does not override the manual environment activation
    scripts.

## Q5. Where should the extension be installed, and how is this achieved in our workspace/worktree setup?

Where to install:

- Install the ESP-IDF extension once in VS Code (WSL context). It is not tied to
  any single worktree; it is a VS Code extension scoped to the WSL environment.
- Configure ESP-IDF paths at the workspace level (the multi-root
  `espruino.code-workspace`) or per-folder `.vscode/settings.json` if needed.
  Workspace-level settings keep all worktrees consistent.

Practical steps (WSL + multi-root workspace):

1) Open the WSL workspace:
   - Use the existing workspace file at `../espruino.code-workspace` so the
     toolchain repo and all worktrees are open together.
   - Launch with the WSL command if needed:
     `code --remote wsl+Ubuntu-22.04 /home/simon/dev/espruino/espruino.code-workspace`

2) Install the ESP-IDF extension in the WSL window:
   - Ensure it is installed in the WSL context (not the Windows side).

3) Run the setup wizard:
   - Command Palette: `ESP-IDF: Configure ESP-IDF Extension`.
   - Choose "Find ESP-IDF in your system" and select
     `~/dev/esp/esp-idf-v4.4.8/` (for this workflow).
   - Select the tools path (keep the default `~/.espressif/` unless there is a
     reason to relocate).
   - Ensure paths are space-free.

4) Keep build ownership with the Makefiles:
   - Use the extension for navigation/monitor/flash as needed, but avoid
     enabling automatic `idf.py build` workflows unless you explicitly want to
     test ESP-IDF project mode.

## Q6. ESP-IDF v4.4.8 esptool installation notes

In ESP-IDF v4.4.8, `esptool` is not installed via `requirements.txt` by
default. It is shipped as a component under
`components/esptool_py/esptool`, so you may need to install it into the IDF
Python venv manually.

Install into the IDF v4.4.8 venv:

```bash
~/.espressif/python_env/idf4.4_py3.10_env/bin/python -m pip install -e /home/simon/dev/esp/esp-idf-v4.4.8/components/esptool_py/esptool
```

Verify:

```bash
~/.espressif/python_env/idf4.4_py3.10_env/bin/python -m esptool --help
```

Notes:
- The ESP-IDF VS Code extension uses the same venv (see `IDF_PYTHON_ENV_PATH`
  in `ESP-IDF: Show Doctor`), so once installed there, the extension will
  find `esptool` automatically.
- If `esptool` still is not detected, reload the VS Code window to refresh
  the extension environment.
