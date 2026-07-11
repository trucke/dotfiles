# .dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/),
organized **by host**:

```
.dotfiles/
├── kratos/         # Mac mini — headless dev/agent box (macOS)
├── loki/           # Framework 13 laptop (Arch + Hyprland via Omarchy)
├── share/          # Cross-host configs, stowed on every machine
└── tmux-fzf-url/   # submodule
```

Host directories are named after each machine's hostname (God of War theme).
Each host has a `just` front door; `share/` holds everything common.

## kratos — Mac mini (dev/agent box)

Homebrew-driven, orchestrated through `just`. `kratos/Brewfile` is the source of
truth for every brew package, cask, and agent (codex/claude/cursor/opencode/pi);
`t3` is the only non-brew agent (pnpm global). Runtimes and dev tools come from
the shared `share/config/mise/config.toml`.

**Fresh machine** — create the `skadi` admin user + enable Remote Login at the
console (needs a monitor once), then SSH in.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/trucke/dotfiles.git ~/.dotfiles   # HTTPS — no SSH key yet on a fresh box
~/.dotfiles/kratos/setup.sh   # system defaults (hostname, network, power, SSH) + full provision
```

`setup.sh` prints the remaining interactive steps (NetBird join, `just
podman-init`, `just t3-serve-install`, agent auth). On an
already-configured box, `just bootstrap` provisions without the system tweaks.

**Day-to-day** (`just` from `~/.dotfiles/kratos`):

```bash
just setup            # converge brew + mise + pnpm agent (t3)
just upgrade          # upgrade all packages (brew + mise + t3)
just upgrade-macos    # macOS point/security update (restarts; returns on its own)
just audit            # current brew/mise state
just cleanup-preview  # what convergence would remove (dry-run)
```

## loki — Framework 13 (Omarchy/Hyprland)

Layered on top of [Omarchy](https://omarchy.org): Omarchy owns the OS lifecycle
(`omarchy update`, `omarchy pkg`, `omarchy theme`) and this repo adds packages,
dotfiles, and Hyprland/tool customizations on top.

**Fresh machine** — install Omarchy first, then:

```bash
git clone git@github.com:trucke/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/loki/setup.sh   # (not `just` — just isn't installed until packages land)
```

**Provision vs. sync.** `setup.sh` runs once (cleanup → packages → dotfiles →
services → config). `sync.sh` is the idempotent "re-assert my customizations"
path — stow dotfiles, Hyprland overrides, package drops, `mise install`, boot
logo. Both `setup.sh` and Omarchy's `post-update` hook call it, so **every
`omarchy update` re-applies everything automatically**.

**Day-to-day** (`just` from `~/.dotfiles/loki`):

```bash
just sync       # redeploy after editing dotfiles (stow + hypr + drops + mise)
just packages   # converge repo + AUR packages after editing the lists
just upgrade    # omarchy update, then mise upgrade
```

### Omarchy customization layer

Omarchy's `hyprland.conf` sources user overrides from `~/.config/hypr/` **after**
its defaults; these are symlinked from `loki/config/hypr/`:

```
input.conf   bindings.conf   looknfeel.conf
```

| Area | Customization |
|------|---------------|
| Displays | kanshi profiles (docked / portable-dual / mobile) — sole authority; auto-disables the internal panel when docked |
| Input | EU layout, caps:escape, vim-style HJKL focus/swap; Kanata home-row mods |
| Keybinds | app launchers (browser, Signal, Obsidian, Proton Pass, T3Chat, mail); hyprshot screenshots |
| Lock / idle | hyprlock + hypridle (lock at 5 min, no screensaver) |
| Agents | opencode (repo) + pi + herdr (AUR) |
| Branding | custom Plymouth boot logo |

## share — common configs

Stowed on every host:

- `zsh` — bundles `.zshenv` (environment + PATH) and `.zshrc` (interactive setup)
- `shell/` — zsh fragments (`env`, `aliases`, `functions`, `init`)
- `config/` — nvim, git, jj, mise, tmux, ghostty, starship, zed, opencode, ripgrep
- `pi/` — pi-coding-agent config (`AGENTS.md`, extensions, skills, themes) → `~/.pi/agent`
- `bin/` → `~/.local/bin`

### Theming

Everything is **Catppuccin Mocha**, static — no theme switching:

- **loki (Hyprland)** follows Omarchy's active theme; set once with `omarchy theme set "Catppuccin"`.
- **Shared CLIs** — ghostty, tmux, starship, neovim, zed — pin Catppuccin Mocha directly.

---

*This README was written with AI assistance.*
