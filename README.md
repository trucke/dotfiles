# .dotfiles

Personal dotfiles managed with GNU Stow. Supports macOS (Homebrew) and Arch Linux (Hyprland via Omarchy).

## Directory structure

```
.dotfiles/
├── macos/                  # macOS bootstrap
│   ├── Brewfile            # Homebrew packages
│   ├── setup.sh            # Main setup script
│   └── scripts/            # System settings, fonts, etc.
│
├── omarchy/                # Arch Linux customization layer (on top of Omarchy)
│   ├── setup.sh            # Main setup script
│   ├── cleanup.sh          # Remove unwanted packages
│   ├── bin/                # Custom scripts (fw13-setup-display, etc.)
│   ├── config/
│   │   ├── hypr/           # Hyprland overrides (monitors, input, bindings, etc.)
│   │   ├── kanata/         # Home-row mods
│   │   ├── kanshi/         # Dynamic monitor profiles
│   │   ├── omarchy/hooks/  # Post-update hook
│   │   └── waybar/         # Custom waybar config
│   ├── icons/              # Web app icons
│   ├── install/            # Install scripts and package lists
│   ├── logo.png            # Custom Plymouth/hyprlock logo
│   └── logo.txt            # ASCII art logo
│
├── share/                  # Shared configs (stowed to ~/.config/)
│   ├── bin/                # Scripts → ~/.local/bin/
│   ├── config/             # Tool configs → ~/.config/
│   │   ├── nvim/           # Neovim (lazy.nvim, LSP)
│   │   ├── ghostty/        # Terminal
│   │   ├── tmux/           # Terminal multiplexer
│   │   ├── git/            # Git config
│   │   ├── mise/           # Dev tool versions
│   │   └── ...
│   ├── shell/              # Shell fragments (aliases, env, functions)
│   ├── zshrc               # → ~/.zshrc
│   └── backgrounds/        # Wallpapers
│
└── tmux-fzf-url/           # Git submodule
```

## Setup

### macOS

```bash
git clone git@github.com:trucke/dotfiles-v2.git ~/.dotfiles
cd ~/.dotfiles/macos
./setup.sh
```

### Arch Linux (Omarchy)

First install [Omarchy](https://omarchy.org), then apply customizations:

```bash
git clone git@github.com:trucke/dotfiles-v2.git ~/.dotfiles
cd ~/.dotfiles/omarchy
./setup.sh
```

The setup script will:
1. Install additional packages
2. Stow dotfiles to ~/.config/
3. Apply Hyprland overrides
4. Set up Kanata (home-row mods) and Kanshi (monitor profiles)
5. Configure shell, default apps, background, and Plymouth logo
6. Remove unwanted packages

## Omarchy customization layer

This setup runs on top of [Omarchy](https://github.com/basecamp/omarchy) (v3.3.3+), a curated Arch Linux + Hyprland distribution.

### Override pattern

Omarchy's `hyprland.conf` sources user override files from `~/.config/hypr/` **after** defaults:

```
monitors.conf   # Display configuration
input.conf      # Keyboard, touchpad, gestures
bindings.conf   # Keybinding overrides
looknfeel.conf  # Appearance settings
```

These files are deployed via hard-link from `omarchy/config/hypr/`.

### Key customizations

| Component | Customization |
|-----------|---------------|
| Monitors | Framework 13 + Lenovo P27h-30 (Kanshi for dynamic switching) |
| Input | EU layout, caps:escape, vim-style HJKL focus/swap |
| Screenshots | hyprshot (replaced slurp/wayfreeze) |
| Lock | hyprlock directly (not omarchy-lock-screen) |
| Apps | T3Chat, Proton Mail, Proton Pass |
| Branding | Custom Plymouth boot logo |

### Post-upgrade hook

After `omarchy-update`, the hook at `~/.config/omarchy/hooks/post-update` automatically re-applies:
- Hyprland override files
- Plymouth logo

### Packages removed

See `omarchy/install/cleanup.packages` for the full list (46 packages including docker, libreoffice, fcitx5, etc.).

---

*This README was written with AI assistance.*
