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

The active checkout is also the deployment source for stow/config links and
should stay advanced to `origin/main`. After publishing from any other checkout,
fast-forward the active checkout immediately; **never deploy by manually copying
files out of a worktree**. Treat active files carefully, preserve unrelated dirty
changes, and inspect divergence before Git operations. The harness provides a
**read-only doctor** plus an optional **isolated worktree helper**, both in this
skill's `doctor.sh`.

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

## Manage: choose the workflow that matches the risk

### Routine, low-risk changes — edit in place

Do **not** create a dedicated worktree for every small config tweak,
documentation correction, package-list adjustment, or closely related follow-up.
For routine changes:

1. Fetch and inspect the target file, relevant config, divergence, and
   `git status` first. If the active branch is behind, fast-forward it with
   `git pull --ff-only` before editing when the current dirty state permits.
2. Edit the source in `~/.dotfiles` directly, preserving unrelated dirty work.
3. Run the narrowest relevant validation and deploy/reload only what changed.
4. Do not commit or push unless the user requested publication.
5. If publication is requested, commit only task files and push normally from
   the active checkout. Never overwrite unrelated changes for a clean status.

A live edit may immediately affect deployed symlinks. This is intentional for
small, well-understood changes, but it makes scoped validation important.
Reuse the current task checkout for related follow-ups instead of creating a
new worktree per tweak.

### Large or critical changes — use an isolated worktree

Use a dedicated worktree for a substantial refactor or a critical change that
needs user review, feedback, staged deployment, or repeated testing before it
becomes live. The helper creates a branch from `origin/main`:

```bash
~/.agents/skills/run-dotfiles/doctor.sh worktree myfix
```

Verified sequence:

```bash
# 1. edit files in ~/.dotfiles-worktrees/myfix
# 2. validate inside the worktree:
~/.agents/skills/run-dotfiles/doctor.sh validate ~/.dotfiles-worktrees/myfix
# 3. request/review user feedback when required
# 4. commit and publish after approval
git -C ~/.dotfiles-worktrees/myfix add -A
git -C ~/.dotfiles-worktrees/myfix commit
git -C ~/.dotfiles-worktrees/myfix push origin feature/myfix:main
# 5. immediately advance the active checkout — this is deployment
git -C ~/.dotfiles pull --ff-only
# 6. validate/reload the active configuration as needed
# 7. clean up (git worktree remove fails because of the submodule):
rm -rf ~/.dotfiles-worktrees/myfix
git -C ~/.dotfiles worktree prune
git -C ~/.dotfiles branch -D feature/myfix
```

Inspect active-checkout dirty paths before the pull. Unrelated changes may remain
in place if they do not conflict; if the fast-forward is blocked, stop and
resolve that state explicitly. Do not copy files from the worktree as a bypass.
Publishing does not update another host automatically: when deployment to Loki
or Kratos is requested, connect to that host, run `git pull --ff-only` there,
and verify the stowed result.

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
| `playwright-mcp` | Install Playwright MCP + headless Chromium for agent web testing |
| `audit` | Current brew/mise state |

(Full list: `just --justfile ~/.dotfiles/kratos/justfile --list`.)

## Deploying this skill

Source of truth is `share/agents/skills/`. `share/bin/link-agent-skills` stows it
to `~/.agents/skills/` and bridges each skill into `~/.claude/skills/`. It runs as
part of `just stow` (kratos) and `sync.sh` (loki); run it by hand after adding a
skill.

## Gotchas (hard-won)

- **A behind active checkout is actionable.** After publishing elsewhere,
  fast-forward `~/.dotfiles` with `git pull --ff-only` so Git state and deployed
  symlinks reference the same revision. Do not leave it intentionally behind.
- **Never manually mirror worktree files into the active checkout.** Publish,
  fast-forward the active repo, then validate/reload. If dirty files block the
  pull, resolve or request guidance rather than creating a split Git/filesystem
  state.
- **Worktrees are selective, not mandatory.** Use direct live edits for routine,
  scoped changes. Reserve isolated worktrees for large or critical work needing
  review/testing, and reuse one worktree for related follow-ups.
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
