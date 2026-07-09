# macos/ — LEGACY / ARCHIVE

This directory is the **old platform-based macOS setup**. It is kept for
reference only and is **no longer maintained**.

The Mac mini (`kratos`) is now provisioned from **`../kratos/`**:

- packages/casks/agents → `kratos/Brewfile`
- provisioning + maintenance → `kratos/justfile` (`just bootstrap`, `just setup`, …)
- macOS security hardening → `kratos/harden.sh`
- language runtimes/dev tools → shared `share/config/mise/config.toml`

Do not run `macos/setup.sh` or `macos/scripts/install-agents.sh` — they reflect
the superseded direct-installer agent approach and an outdated Brewfile.
