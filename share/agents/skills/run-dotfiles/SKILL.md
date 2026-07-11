---
name: run-dotfiles
description: Manage, operate, update, deploy, stow, sync, and health-check the host-based dotfiles repo at ~/.dotfiles (kratos = macOS, loki = Arch/Omarchy, share = common). Use when asked to run the dotfiles doctor, safely edit and publish dotfiles, deploy/re-stow configs, or diagnose symlink/just/git health.
---

# run-dotfiles

Cross-agent skill (Agent Skills format) for the personal dotfiles repo at
**`~/.dotfiles`** (override with `$DOTFILES`) — managed with **GNU Stow**, laid
out **by host**: `kratos/` (Mac mini, macOS), `loki/` (Framework 13, Arch +
Omarchy/Hyprland), `share/` (common, stowed everywhere). There is no app to
launch — the repo is *deployed* with stow and *operated* through per-host `just`
recipes.

The one thing that reliably bites here: **the live checkout is intentionally
kept behind `origin/main`** because the live stow symlinks pin a specific layout.
Editing, committing, or stowing on the live tree corrupts a running machine. So
the harness is a **read-only doctor** plus a **safe-edit worktree helper**, both
in this skill's `doctor.sh`.

This skill lives in the repo at `share/agents/skills/run-dotfiles/` and is
deployed to **`~/.agents/skills/run-dotfiles/`** (read natively by codex, cursor,
opencode, pi) and bridged into `~/.claude/skills/` for Claude Code. The driver is
at **`~/.agents/skills/run-dotfiles/doctor.sh`** and takes the repo path as an
argument (default `$DOTFILES` or `~/.dotfiles`).

## Prerequisites

`git`, `stow`, `just` are required; `shellcheck` is optional (enables the
script-lint check). On a provisioned box they're already present (loki: pacman/
Omarchy; kratos: Homebrew). The driver reports which are missing.

## Health check — the agent path (run this first)

```bash
# Full read-only health check of the live repo (git state + stow + just + lint):
~/.agents/skills/run-dotfiles/doctor.sh          # defaults to $DOTFILES or ~/.dotfiles
```

Verified output: tooling ✓, repo section (branch, HEAD, `origin/main`,
ahead/behind, dirty count, active worktrees), host auto-detected from hostname,
`just` recipes parse-checked, shell scripts shellcheck'd, and `share/` packages
dry-run-stowed for conflicts. It exits **0** on pass/warn, **1** on a hard
failure (missing tool or a justfile that won't parse). Stow conflicts are
**warnings, not failures** — they're expected on a machine mid-migration.

```bash
~/.agents/skills/run-dotfiles/doctor.sh doctor /path/to/other/checkout   # explicit repo
~/.agents/skills/run-dotfiles/doctor.sh --help                          # commands + exit semantics
```

## Manage: safe edit → publish (never touch the live tree)

Use the worktree helper. It creates a branch off `origin/main`, so you edit the
*current* layout, not the frozen live checkout:

```bash
~/.agents/skills/run-dotfiles/doctor.sh worktree myfix
```

It prints the exact five-step flow it set up. Verified sequence:

```bash
# 1. edit files in  ~/.dotfiles-worktrees/myfix
# 2. validate (no remote compare; run inside the worktree):
~/.agents/skills/run-dotfiles/doctor.sh validate ~/.dotfiles-worktrees/myfix
# 3. commit
git -C ~/.dotfiles-worktrees/myfix add -A && git -C ~/.dotfiles-worktrees/myfix commit
# 4. publish — fast-forward the branch straight onto main:
git -C ~/.dotfiles-worktrees/myfix push origin feature/myfix:main
# 5. clean up (rm -rf, NOT `git worktree remove` — it fails on the submodule):
rm -rf ~/.dotfiles-worktrees/myfix
git -C ~/.dotfiles worktree prune
git -C ~/.dotfiles branch -D feature/myfix
```

**Do not** `git checkout`/`merge` `origin/main` on the live tree, and **do not**
update local `main`. The push in step 4 moves the remote forward without
touching the running machine's symlinks.

## Operate & update — per-host `just` recipes

These run **on the target host** and mutate it, so they aren't executed by the
doctor; they were parse-verified with `just --justfile <host>/justfile --list`
(that command *is* safe to run anywhere). Invoke from the host dir, e.g.
`just -f ~/.dotfiles/<host>/justfile <recipe>`:

**loki** (Arch/Omarchy — day-to-day is `omarchy update`, whose post-update hook
runs `sync.sh` automatically):

| Recipe | What it does |
|---|---|
| `sync` | Re-assert customizations (stow, hypr overrides, pkg drops, mise, agent skills) — after editing dotfiles |
| `packages` | Converge repo + AUR packages from the lists |
| `upgrade` | `omarchy update`, then `mise upgrade` |
| `setup` | Fresh-provision (cleanup → packages → dotfiles → services → config) |

**kratos** (macOS — Homebrew-driven):

| Recipe | What it does |
|---|---|
| `setup` | Converge brew + mise + pnpm agent |
| `upgrade` | Upgrade all packages (brew + mise + t3) |
| `upgrade-macos` | macOS point/security update (restarts; returns on its own) |
| `t3-serve-restart` | Restart the `t3 serve` daemon + print a fresh pairing token/URL |
| `browser-init` | Install Playwright MCP + headless Chromium for agent web testing |
| `audit` | Current brew/mise state |

(Full list: `just --justfile ~/.dotfiles/kratos/justfile --list`.)

## Deploying this skill

Source of truth is `share/agents/skills/`. `share/bin/link-agent-skills` stows it
to `~/.agents/skills/` and bridges each skill into `~/.claude/skills/`. It runs as
part of `just stow` (kratos) and `sync.sh` (loki); run it by hand after adding a
skill.

## Gotchas (hard-won)

- **The live checkout is deliberately behind `origin/main`.** The doctor's
  "behind by N" warning is *normal* — live symlinks point at the current on-disk
  layout. It converges only when the machine is reinstalled.
- **Never edit/commit/stow on the live tree.** Always the worktree flow above.
  Publishing is `git push origin feature/<name>:main` (fast-forward), never a
  local-main merge.
- **`git worktree remove` fails** because of the `tmux-fzf-url` submodule. Remove
  a worktree with `rm -rf <dir>` then `git worktree prune`.
- **Claude bridge is per-skill, not a whole-dir symlink.** `~/.claude/skills/` also
  holds `omarchy` (a symlink); a whole-dir symlink would drop it.
- **`stow` "existing target is not owned by stow"** means that path is a live
  symlink into a *different* tree. Expected mid-migration — only stow for real on
  a freshly-provisioned box.
- **`[confirm(...)]` recipes block on stdin.** `just --dry-run <confirm-recipe>`
  still prompts and will hang a non-interactive shell — redirect `</dev/null`.
- **Public repo.** No secrets, IPs, prod hostnames, or keys in committed files.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Doctor: `no justfile found` / `just recipes` empty | Hostname doesn't match a host dir. Pass the host justfile explicitly: `just --justfile ~/.dotfiles/<host>/justfile --list`. |
| Doctor: stow `CONFLICT` on a live machine | Expected if mid-migration (symlinks point at another tree). Only a concern on a box you're actively provisioning. |
| Skill not visible to Claude | `~/.claude/skills/run-dotfiles` bridge missing — run `link-agent-skills`. |
| Skill not visible to codex/cursor/opencode/pi | They read `~/.agents/skills/` — confirm `~/.agents/skills/run-dotfiles/` exists (run `link-agent-skills`). |
| `doctor.sh` targets the wrong repo | Defaults to `$DOTFILES` or `~/.dotfiles`; pass an explicit path or `export DOTFILES=/path`. |
