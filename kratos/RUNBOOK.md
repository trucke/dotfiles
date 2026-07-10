# kratos — reinstall & setup runbook

Rebuild the Mac mini (`kratos`) from zero as user **`skadi`**. It's a **headless,
Apple-Silicon** box reached only over SSH via NetBird — that shapes almost every
step below. The README has the short version; this is the full flow plus the
gotchas that actually bite.

> **You need a monitor + keyboard once.** A fresh macOS install + Setup Assistant
> can't be done fully headless. Attach a display for steps 1–3, then go headless.

---

## 1. Before you wipe

- **Sign out of iCloud / turn off Find My** (System Settings → your name → Sign
  Out). This clears **Activation Lock** so the reinstall isn't locked. *(Erase
  All Content and Settings does this for you.)*
- **Back up local-only data** — `~/development` (uncommitted work), `~/Documents`.
  Ollama models are re-downloadable. Dotfiles are safe on GitHub.
- Have ready: **Apple ID**, the **`skadi`** password, an **Ethernet cable**
  (far more reliable than Wi-Fi for a headless box), and **loki reachable** (you'll
  scp SSH keys from it — see §5).

## 2. Erase & reinstall macOS

- **Easiest:** System Settings → General → Transfer or Reset → **Erase All
  Content and Settings**. Clears Activation Lock + FileVault, keeps the OS.
- **Clean reinstall:** hold the power button → **Options** → Disk Utility erase
  the internal disk (APFS) → quit → **Reinstall macOS**.

## 3. First boot — create `skadi`, enable SSH (monitor attached)

Setup Assistant: region → **plug in Ethernet** → Migration Assistant **Not Now**
→ Apple ID (or Set Up Later) → **create admin user `skadi`** ← the key step →
turn **off** Siri/Analytics/Screen Time.

Then: System Settings → General → **Sharing → Remote Login: ON** (allow `skadi`).
Note the IP. **Now you can SSH in and unplug the monitor.**

## 4. Bootstrap (over SSH)

```bash
ssh skadi@<mac-mini-ip>
```
```bash
# 1. Homebrew — also installs the Command Line Tools (git)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone over HTTPS — the repo is PUBLIC, so no SSH key is needed yet
git clone https://github.com/trucke/dotfiles.git ~/.dotfiles

# 3. Provision
~/.dotfiles/kratos/setup.sh
```

`setup.sh` sets the hostname (`kratos`), timezone, Remote Login, power (never
sleep, WoL, auto-restart), then runs `just bootstrap` and `just ssh-keys`, and
prints the interactive checklist (§5).

**What `just bootstrap` does, in order** (the order matters — see Gotchas):
`brew` (Brewfile + trusts the 3rd-party taps) → `stow` (dotfiles, incl. the mise
config) → `harden` → `mise install` → `pnpm-globals` (t3).

## 5. Post-install checklist (interactive)

1. **Register the generated pubkeys** — `~/.ssh/github` → GitHub Settings;
   `~/.ssh/net` → loki's `~/.ssh/authorized_keys`.
2. **Shared SSH keys + host config — scp from loki** (the Proton Pass CLI can't
   run headless — see Gotchas). On **loki**, export the shared keys + `hosts.conf`
   from Proton Pass, then:
   ```bash
   scp <key1> <key2> <key3> <key4>  skadi@<kratos>:~/.ssh/
   scp hosts.conf                   skadi@<kratos>:~/.ssh/config.d/
   ssh skadi@<kratos> 'chmod 700 ~/.ssh ~/.ssh/config.d; chmod 600 ~/.ssh/<keys> ~/.ssh/config.d/hosts.conf'
   ```
3. **NetBird:** `netbird up` (SSO login) → kratos is reachable at its NetBird IP.
4. **Podman:** `just -f ~/.dotfiles/kratos/justfile podman-init` — installs the
   **official Podman `.pkg`** (not brew), inits + starts the machine, wires
   `docker.sock`.
5. **t3 serve:** `just -f ~/.dotfiles/kratos/justfile t3-serve-install` — installs
   the LaunchDaemon (persistent, bound to the NetBird IP, boot-start + auto-restart).
6. **Agents:** `codex` · `claude` · `cursor-agent` · `opencode` (`/connect`) ·
   `pi` (`/login`) · `t3`.
7. **Time Machine:** `just -f ~/.dotfiles/kratos/justfile timemachine` (NAS over SMB).

## 6. Verify

```bash
ssh kratos                                  # via NetBird
netbird status                              # connected
podman machine ls                           # running; docker ps works
sudo launchctl print system/com.t3code.serve | grep -iE 'state|pid'   # t3 daemon running
tmutil status                               # backing up
```

## 7. Day-to-day

`just` from `~/.dotfiles/kratos`:
- `just upgrade` — brew + mise + t3
- `just upgrade-macos` — macOS point/security update (restarts; returns on its own)
- `just audit` — current brew/mise state
- `just cleanup-preview` — what convergence would remove (dry-run)

---

## Gotchas & troubleshooting

*(These are the things that broke during the first real rebuild — all now handled
by the scripts, documented here so a future you knows why.)*

- **Clone with HTTPS, not SSH.** A fresh box has no SSH key yet, and `just stow`
  needs `stow` (a Brewfile entry). The repo is public → `git clone https://…`.
  Switch the remote to SSH later: `git -C ~/.dotfiles remote set-url origin git@github.com:trucke/dotfiles.git`.
- **The macOS application firewall is intentionally OFF** (`harden.sh`). kratos
  serves over NetBird's private mesh; the app firewall + stealth mode silently
  **drop** incoming connections to served ports (t3 serve, podman) with no benefit
  behind a private WireGuard mesh. Symptom if it's ever re-enabled: services are
  reachable via TCP but HTTP **times out**.
- **The headless Keychain wall.** Anything using the macOS login Keychain fails
  over SSH ("User interaction is not allowed" / "secure storage unavailable"):
  - **Proton Pass CLI** (`pass-cli`) can't unlock → **retrieve shared keys on loki
    and scp them** (step 5.2). Don't fight it on kratos.
  - t3 serve itself is fine (no Keychain needed to start).
- **Podman = official installer, not Homebrew.** Podman doesn't recommend the brew
  formula (it omits the machine VM provider → `krunkit: not found` / exit 2).
  `just podman-init` installs `podman-installer-macos-arm64.pkg` from the latest
  release (bundles gvproxy + libkrun). `podman` lives in `/opt/podman/bin`.
- **`podman-mac-helper` before `machine start`.** The helper wires `docker.sock`;
  installed after start, the socket isn't live until the next restart. `podman-init`
  orders it correctly; if you did it by hand, `podman machine stop && start`.
- **t3 pairing token is short-lived / single-use.** It changes on every `t3 serve`
  start and expires quickly. To pair: mint a fresh one and pair within a minute:
  ```bash
  just -f ~/.dotfiles/kratos/justfile t3-serve-restart   # restarts + prints the fresh token/URL
  ```
  Pair the loki client at the printed `http://<kratos-netbird-ip>:3773` + token.
  Once paired, the credential persists.
- **loki t3code client needs an Electron flag.** t3code's bundled Electron has a
  safeStorage bug on Hyprland (`pingdotgg/t3code#2880`) → "secure storage
  unavailable" when saving the connection. Fixed by launching with
  `--password-store=gnome-libsecret` (version-controlled at
  `loki/applications/t3code.desktop`).
- **NetBird reverse proxy = public exposure.** Its HTTPS service exposes t3 to the
  **internet** (the private "NetBird-Only Access" needs a self-hosted embedded
  proxy you don't have). For a private agent host, **skip it** — pair the client
  directly over the mesh (`http://<netbird-ip>:3773`).
- **PATH / macOS `path_helper`.** `/etc/zprofile` reorders PATH after `.zshenv` on
  login shells; `.zshrc` re-sources `share/shell/path` to put Homebrew + our dirs
  back in front. If `which git` shows `/usr/bin/git`, you're in a shell that
  predates the dotfiles — start a fresh one.
