# AGENTS.md

Guidelines for AI coding agents operating in this dotfiles repository.

## Repository overview

Personal dotfiles managed with GNU Stow. Supports macOS (Homebrew) and Arch Linux (Hyprland).
Configs are symlinked from `share/` into `~/.config/`, `~/.local/bin/`, and `~/`.

## Directory structure

```
macos/              # macOS bootstrap: Brewfile, setup.sh, system settings
omarchy/            # Arch Linux bootstrap: install scripts, Hyprland/Waybar/Kanata configs
share/
  bin/              # Scripts stowed to ~/.local/bin/ (tmux-sessionizer, etc.)
  config/           # XDG configs stowed to ~/.config/ (nvim, git, jj, ghostty, tmux, mise, etc.)
  shell/            # Shell fragments sourced by zshrc: aliases, env, functions, init
  zshrc             # Stowed to ~/.zshrc
  backgrounds/      # Wallpapers
```

## Build / lint / test commands

This is a dotfiles repo — there is no build system, test suite, or CI pipeline.

```sh
# Validate shell scripts (shfmt is installed via mise)
shfmt -d -i 2 <file.sh>          # diff check
shfmt -w -i 2 <file.sh>          # format in place

# Validate Lua files (stylua is installed via Mason in nvim)
stylua --check share/config/nvim/
stylua share/config/nvim/         # format in place

# Apply dotfiles via stow (from repo root)
stow --restow --dir=share --target="${HOME}" zshrc
stow --restow --dir=share --target="${HOME}/.config" config
stow --restow --dir=share --target="${HOME}/.local/bin" bin

# Run full macOS setup
bash macos/setup.sh

# Run full Arch setup
bash omarchy/setup.sh
```

There are no tests to run. Validation is manual: source the shell config or restart the relevant tool.

## Version control

- This repo uses **git only** (no jj colocated). Use git commands here.
- In other project repos: prefer jj over git when a `.jj/` directory exists.
- Commit messages: short imperative form (e.g., "add ghostty config", "update nvim keymaps").
- The `devcommit` alias exists but prefer descriptive commit messages over "automated dev commit".

## Code style

### Shell (Bash/Zsh)

- Shebang: `#!/usr/bin/env bash` for scripts. Shell fragments (aliases, env, functions, init) have no shebang.
- Use `set -euo pipefail` in standalone scripts.
- Indent with **2 spaces** (shfmt configured with `-i 2`).
- Use `local` for function variables.
- Quote variables: `"${var}"` — use braces for clarity.
- Guard commands with `command -v` before using them (see `share/shell/init`).
- Functions use snake_case or kebab-case (match the file they're in).
- Comments explain why, not what. Use `#` with a single space.
- No trailing whitespace. End files with a newline.

### Lua (Neovim config)

- Indent with **tabs** (Neovim plugin files use `-- vim: ts=2 sts=2 sw=2 et` modeline for 2-space display).
- Plugin specs: one file per plugin or logical group in `share/config/nvim/lua/plugins/`.
- Each plugin file returns a table (or list of tables) for lazy.nvim.
- Use `require("module")` with double quotes.
- Keymaps include a `desc` field for which-key discovery.
- LSP servers are declared in `plugins/lsp.lua` in the `servers` table.
- Formatters are declared in `plugins/conform.lua` in `formatters_by_ft`.
- Type annotations use `---@type` and `---@module` LuaCATS comments where helpful.

### TOML configs

- Used for: mise, jj, starship. Follow existing key ordering.
- mise pins tools to `"latest"` in `share/config/mise/config.toml`.

### General

- No commented-out code left behind (remove or delete, don't comment).
- No TODO/FIXME/HACK comments — fix it now or don't add it.
- Prefer editing existing files over creating new ones.
- kebab-case for filenames where possible.

## Stow conventions

- Stow source dirs are under `share/`. Target mappings:
  - `share/zshrc` -> `~/`
  - `share/config/` -> `~/.config/`
  - `share/bin/` -> `~/.local/bin/`
- `.stow-local-ignore` excludes: `macos/`, `share/`, `omarchy/`, `tmux-fzf-url/`, `.git*`, `README`.
- New configs go into `share/config/<tool>/` to be stowed automatically.
- After adding/changing stowed files, re-run the appropriate `stow --restow` command.

## Environment conventions

- All XDG base dirs are explicitly set in `share/shell/env` — respect them.
- Tool data goes under `XDG_DATA_HOME`, caches under `XDG_CACHE_HOME`.
- `$EDITOR`, `$VISUAL`, `$GIT_EDITOR` are all `nvim`.
- Telemetry is disabled globally (`HOMEBREW_NO_ANALYTICS`, `DOTNET_CLI_TELEMETRY_OPTOUT`, `DISABLE_TELEMETRY`).

## Key tools in the environment

| Tool     | Purpose                        | Config location                     |
|----------|--------------------------------|-------------------------------------|
| Neovim   | Editor (Lazy.nvim, LSP, etc.)  | `share/config/nvim/`                |
| Ghostty  | Terminal emulator              | `share/config/ghostty/config`       |
| tmux     | Terminal multiplexer           | `share/config/tmux/tmux.conf`       |
| Starship | Shell prompt                   | `share/config/starship.toml`        |
| mise     | Dev tool version manager       | `share/config/mise/config.toml`     |
| git      | Version control                | `share/config/git/config`           |
| jj       | Version control (other repos)  | `share/config/jj/config.toml`       |
| fzf      | Fuzzy finder                   | Configured in `share/shell/env`     |
| OpenCode | AI coding agent                | `share/config/opencode/`            |

## Platform-specific notes

- **macOS**: Homebrew manages packages (`macos/Brewfile`). System settings in `macos/scripts/settings.sh`.
- **Arch Linux**: Packages via paru/yay. Install scripts are modular in `omarchy/install/`.
- Shared configs in `share/` work on both platforms. Platform-specific code stays in `macos/` or `omarchy/`.

## Principles

- **KISS**: Prefer simple solutions. Use built-in language/framework features over custom abstractions.
- **YAGNI**: No code for hypothetical futures. Delete unused code.
- **Follow existing patterns**: Match the style, structure, and conventions already in the codebase.
- **Comments explain why, not what**: Prefer self-documenting code.

## Guardrails

- **No dependencies without approval**: Ask before adding Homebrew packages, mise tools, or Neovim plugins.
- **No secrets in code**: Never commit credentials, API keys, or sensitive data.
- **Don't modify unrelated code**: Stay focused on the task. No drive-by refactors.
- **Prefer editing over creating files**: Modify existing files when possible.
- **Don't touch global/system config**: Never modify files outside this repo (e.g., `~/.bashrc` directly).
- **Ask before large changes**: New tools, plugins, or structural changes require approval.
- **Do what was asked**: Complete the task as specified. No gold-plating.

## Workflow

- **Verify before assuming**: Read the config before guessing how it works.
- **Research, then ask**: For ambiguous requests, explore the codebase first.
- **Remove debug code**: No leftover print statements or commented-out code.
- **Commit only when asked**: Stage changes but don't commit unless explicitly requested.

## Specs workflow

- Specs live in `specs/` with a flat structure and kebab-case filenames.
- Status lifecycle: Proposal -> Draft -> Ready -> Implemented.
- Only implement when the spec is Ready; update status to Implemented after shipping.
