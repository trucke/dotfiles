# .dotfiles

Personal dotfiles managed with GNU Stow, organized **by host**:

```
.dotfiles/
├── kratos/         # Mac mini dev/agent box (macOS)
├── loki/           # Framework 13 laptop (Arch + Hyprland via Omarchy)
├── share/          # Cross-platform configs (stowed on every host)
├── macos/          # LEGACY — old platform-based macOS setup (archived)
└── tmux-fzf-url/   # submodule
```

Host directories are named after the machines' hostnames (God of War theme):
`kratos` (Mac mini), `loki` (FW13). `share/` holds everything common.

## kratos (Mac mini)

Provisioned and maintained through a `just` interface.

**Fresh machine** (clean macOS install + admin user; enable Remote Login at the
console once, then SSH in with `-A` so `git` can use your forwarded key):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone git@github.com:trucke/dotfiles.git ~/.dotfiles
~/.dotfiles/kratos/setup.sh   # system defaults (hostname, network, power, SSH) + full provision
```

`setup.sh` then prints the remaining interactive steps (NetBird join,
`just podman-init`, FileVault, agent auth, `t3 serve`). To provision an
already-configured box, use `just bootstrap`.

**Day-to-day:**

```bash
just setup            # converge brew + mise + pnpm agent (t3)
just upgrade          # upgrade all packages (brew + mise + t3)
just upgrade-macos    # macOS point/security update (authenticated restart)
just audit            # current brew/mise state
just cleanup-preview  # what convergence would remove (dry-run)
```

- `kratos/Brewfile` — source of truth for all brew-managed packages, casks, and
  agents (codex/claude/cursor/opencode/pi). `t3` is the only non-brew agent (pnpm).
- `kratos/harden.sh` — macOS security hardening (headless-appropriate).
- Runtimes/dev tools come from the shared `share/config/mise/config.toml`.

## loki (Framework 13, Omarchy)

First install [Omarchy](https://omarchy.org), then apply customizations:

```bash
git clone git@github.com:trucke/dotfiles.git ~/.dotfiles
cd ~/.dotfiles/loki
./setup.sh
```

The setup script installs packages, stows dotfiles, applies Hyprland overrides,
sets up Kanata (home-row mods) + Kanshi (monitor profiles), configures shell,
apps, background, and Plymouth logo, and removes unwanted packages.

### Omarchy customization layer

Runs on top of [Omarchy](https://github.com/basecamp/omarchy). Omarchy's
`hyprland.conf` sources user overrides from `~/.config/hypr/` **after** defaults:

```
monitors.conf   input.conf   bindings.conf   looknfeel.conf
```

deployed via symlink from `loki/config/hypr/`.

| Component | Customization |
|-----------|---------------|
| Monitors | Framework 13 + Lenovo P27h-30 (Kanshi dynamic switching) |
| Input | EU layout, caps:escape, vim-style HJKL focus/swap |
| Screenshots | hyprshot |
| Lock | hyprlock directly |
| Apps | T3Chat, Proton Mail, Proton Pass |
| Branding | Custom Plymouth boot logo |

After `omarchy-update`, the hook at `~/.config/omarchy/hooks/post-update`
re-drops unwanted packages, removes conflicting defaults, re-stows dotfiles, and
re-applies the theme + Hyprland overrides.

## share (common)

Stowed on every host:

- `shell/` — zsh fragments (`env`, `aliases`, `functions`, `init`, per-OS `macos`/`linux`)
- `config/` — nvim, git, jj, mise, tmux, ghostty, opencode, …
- `bin/` → `~/.local/bin`
- `zshenv`, `zshrc`
- `backgrounds/`

### Theming

Everything is **Catppuccin Mocha**, statically — no theme switching:

- **loki (Hyprland)** follows Omarchy's active theme; set once with `omarchy theme set "Catppuccin"`.
- **Shared CLIs** — ghostty, tmux, starship, and neovim pin Catppuccin Mocha directly.

## macos/ (legacy)

The previous platform-based macOS setup, kept for reference only — superseded by
`kratos/`. See `macos/LEGACY.md`.

---

*This README was written with AI assistance.*
