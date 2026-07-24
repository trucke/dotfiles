# .dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/),
organized by host:

```
.dotfiles/
├── kratos/         # Mac mini — headless remote dev box (macOS)
├── loki/           # Framework 13 daily driver (Arch + Omarchy)
├── share/          # Cross-host configuration
└── tmux-fzf-url/   # tmux fallback plugin (submodule)
```

## Development workflow

Kratos is the default for substantive coding. Loki is the daily-driver UI and
handles offline work, quick fixes, dotfiles, and tasks that do not need Kratos.
Repositories are independent clones; Git/Jujutsu is the synchronization boundary.
Agent sessions remain on the host and checkout where they started.

| Layer | Primary | Fallback / complement |
|---|---|---|
| Coding harness | Pi with the OpenAI Codex provider | Claude Code |
| Persistent terminal | Herdr | tmux (not nested inside Herdr) |
| Editor | Neovim in terminals | Zed GUI on Loki |
| Remote transport | NetBird + SSH | — |
| Review | CodeRabbit | Pi / Claude |

From Loki:

```bash
herdr                 # local persistent herd
hk                    # native Herdr remote attach to Kratos
ssh kratos            # ordinary remote shell; also the iPad path
```

Each host uses one default Herdr session with workspaces/tabs per project. Use one
writing agent per checkout. Parallel agents require deliberately separate
worktrees or clones.

Zed runs only on Loki. Its Remote Projects connection uses the `kratos` SSH alias;
remote language servers, tasks, terminals, debugger, Pi ACP, and Claude ACP run
with the Kratos checkout. Development services stay bound to remote localhost and
use SSH local forwarding. Add forwards per project rather than exposing ports on
the mesh.

## kratos — Mac mini

Homebrew manages infrastructure, applications, Herdr, Claude Code, and CodeRabbit.
Pi is installed directly from its upstream npm package with pnpm after mise has
installed Node and pnpm:

```bash
pnpm add -g --ignore-scripts @earendil-works/pi-coding-agent
pi update
```

**Fresh machine:** create the `skadi` admin user and enable Remote Login at the
console, then SSH in:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone https://github.com/trucke/dotfiles.git ~/.dotfiles
~/.dotfiles/kratos/setup.sh
```

`setup.sh` configures hostname, networking, power, SSH, packages, dotfiles, and
hardening. It prints the remaining interactive steps for keys, NetBird, Podman,
agent authentication, optional Playwright MCP, and Syncthing.

Day-to-day from `~/.dotfiles/kratos`:

```bash
just setup            # converge brew, dotfiles, mise, Pi, and Herdr integrations
just upgrade          # explicit package, mise, and Pi updates
just upgrade-agents   # explicit Pi, Claude, Herdr, and CodeRabbit updates
just upgrade-macos    # macOS update and restart
just audit            # current brew/mise state
just cleanup-preview  # show unmanaged brew packages
```

Kratos keeps its existing RustDesk/full-GUI escape hatch, but Zed desktop, Mosh,
Codex CLI, Cursor CLI, OpenCode, and T3Code are not provisioned. On an existing
host, run `just setup`, verify Pi/Claude/Herdr, then run the confirmed one-time
`just retire-legacy-tools` recipe.

## loki — Framework 13

Loki layers this repository on top of [Omarchy](https://omarchy.org/). Omarchy
owns the OS lifecycle; the repository adds packages, dotfiles, and Hyprland/tool
customizations.

**Fresh machine:** install Omarchy first, then:

```bash
git clone https://github.com/trucke/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/loki/setup.sh
jj -R ~/.dotfiles git remote set-url origin git@github.com:trucke/dotfiles.git
```

`setup.sh` runs cleanup, package installation, dotfile sync, services, and system
configuration. `sync.sh` is the idempotent convergence path and runs after each
`omarchy update` through the post-update hook.

Day-to-day from `~/.dotfiles/loki`:

```bash
just sync             # reassert dotfiles, tools, services, and Hypr overrides
just packages         # converge repo/AUR package lists
just upgrade          # explicit Omarchy, mise, and coding-tool updates
just upgrade-agents   # explicit Pi, Claude, Herdr, OpenCode, CodeRabbit updates
```

Pi uses the same upstream pnpm installation as Kratos. Claude Code uses
Anthropic's native Linux installer with background updates disabled through the
documented `DISABLE_AUTOUPDATER=1` setting; `claude update` remains explicit.
`opencode-bin` stays installed without managed config, completion, or Herdr
integration for occasional experiments. On an existing host, run `just sync`,
verify the upstream Pi and native Claude installs, then run the confirmed
one-time `just retire-legacy-tools` recipe.

### Omarchy customization layer

Omarchy's `hyprland.conf` sources overrides from `~/.config/hypr/` after its
defaults. The repository deploys:

```
monitors.conf   input.conf   bindings.conf   looknfeel.conf   autostart.conf
```

| Area | Customization |
|---|---|
| Displays | Framework/Dell rules plus clamshell reconciliation and focused-workspace handoff |
| Input | EU layout, caps:escape, vim-style HJKL focus/swap, Kanata home-row mods |
| Keybinds | Browser, Signal, Obsidian, Proton Pass, mail, and screenshots |
| Lock / idle | hyprlock + hypridle (lock at 5 minutes) |
| Power | User service keeps `power-profiles-daemon` balanced |
| Coding | Pi, Claude Code, Herdr, Zed, and experimental OpenCode |
| Branding | Custom Plymouth boot logo |

#### Clamshell compatibility

The local clamshell layer exists for Omarchy v3.8.3:

- `loki/bin/omarchy-lid-close-external`
- `loki/bin/omarchy-lid-open`
- `loki/bin/omarchy-lid-watch`
- lid overrides in `loki/config/hypr/bindings.conf`
- watcher launch in `loki/config/hypr/autostart.conf`

Reassess it after an Omarchy release containing the Quattro clamshell work. Test
focused-workspace preservation, closed-lid keyboard use, reopen, connecting the
Dell while closed, and unplug recovery before removing it.

## Shared configuration

`share/` deploys:

- zsh and common shell fragments
- Git/Jujutsu, mise, Neovim, tmux, Ghostty, Starship, and ripgrep
- Herdr configuration and Pi/Claude integration convergence
- Pi context, extensions, skills, themes, and the pinned `pi-setup` package
- vendor-neutral Agent Skills bridged into Claude Code
- shared utilities under `~/.local/bin`

Git uses a writable host-local `~/.config/git/config` that includes the tracked
`~/.config/git/config.shared` followed by optional host overrides in
`~/.config/git/config.local`. This keeps generated settings such as CodeRabbit's
machine ID local while preserving shared Git defaults.

## Version-control workflow

The repository is a colocated Jujutsu/Git workspace. Use jj for daily work; Git
remains for bootstrap, GitHub compatibility, and the tmux submodule.

```bash
cd ~/.dotfiles
jj status
jj git fetch
jj rebase -b @ -o main

# edit and validate
jj diff
~/.agents/skills/run-dotfiles/doctor.sh validate ~/.dotfiles

# publish only when intended
jj describe -m "type(scope): description"
jj bookmark move main --to @
jj git push --bookmark main
jj new main
```

The active checkout is Stow's live deployment source. Use an isolated jj
workspace for risky SSH, shell, Hyprland, Stow, or provisioning changes.

## Theming

Everything uses static Catppuccin Mocha:

- Omarchy follows its active Catppuccin theme.
- Ghostty, tmux, Starship, Neovim, and Zed pin their matching theme.
