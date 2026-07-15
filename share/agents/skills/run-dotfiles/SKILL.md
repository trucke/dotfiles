---
name: run-dotfiles
description: Manage, operate, update, deploy, stow, sync, and health-check the host-based dotfiles repo at ~/.dotfiles (kratos = macOS, loki = Arch/Omarchy, share = common). Use when asked to run the dotfiles doctor, safely edit and publish dotfiles, deploy/re-stow configs, or diagnose symlink/just/jj health.
---

# run-dotfiles

Cross-agent skill for the personal dotfiles repo at **`~/.dotfiles`** (override
with `$DOTFILES`). GNU Stow deploys `kratos/` (macOS), `loki/` (Arch + Omarchy),
and `share/` (common). The repository uses a **colocated Jujutsu/Git workspace**:
Jujutsu is the day-to-day VCS; Git remains for GitHub compatibility, fresh-box
bootstrap, and the `tmux-fzf-url` submodule.

The active checkout is also Stow's live deployment source. A normal edit may
immediately affect the running machine. Always inspect the current jj change
before editing, preserve unrelated work, and move `main` only when publication
was explicitly requested.

## Prerequisites

`jj`, `git`, `stow`, and `just` are required. `shellcheck` is optional. On a
fresh machine Git performs the initial clone; host setup installs jj with mise
and initializes the colocated workspace.

## Health check — run first

```bash
~/.agents/skills/run-dotfiles/doctor.sh
```

The doctor fetches `origin`, then reports tooling, colocation, the current
working-copy change, conflicts, `main`/`main@origin`, bookmark tracking, jj
workspaces, the Git submodule, host detection, justfile parsing, shellcheck, and
Stow dry-runs. Fetching updates repository metadata but does not publish or
rewrite work.

```bash
~/.agents/skills/run-dotfiles/doctor.sh validate /path/to/workspace  # no fetch
~/.agents/skills/run-dotfiles/doctor.sh --help
```

## Routine workflow — edit the live checkout

Use the active checkout for normal scoped work. Keep one logical task in `@`.
Do not introduce feature bookmarks for routine changes in this personal,
main-only repository.

1. Inspect and update:

   ```bash
   cd ~/.dotfiles
   jj status
   jj git fetch
   jj rebase -b @ -o main
   ```

   If `@` already contains unrelated work, do not mix tasks. Use an isolated
   workspace or ask how to proceed. Resolve a conflicted `main` explicitly
   before rebasing.

2. Edit and review:

   ```bash
   jj diff
   ~/.agents/skills/run-dotfiles/doctor.sh validate ~/.dotfiles
   ```

3. Deploy or reload only what changed. A Stow-managed source edit may already be
   live; use the relevant host recipe when convergence is needed.

4. Do not publish unless requested. To publish the current reviewed change:

   ```bash
   jj describe -m "type(scope): description"
   jj bookmark move main --to @
   jj git push --bookmark main
   jj new main
   ```

`@` is the draft, `main` is the published line, and `jj new main` creates the
next empty draft. There is no staging area. Use `jj split` when one draft needs
to become multiple changes.

## Isolated workflow — only when filesystem isolation matters

A jj workspace is not needed for ordinary branching. Use one when:

- a change could break SSH, shell startup, Hyprland/session startup, Stow, or
  provisioning;
- unrelated work in the live `@` must remain deployed;
- a substantial change needs review before it affects the machine.

Create it with:

```bash
~/.agents/skills/run-dotfiles/doctor.sh workspace myfix
```

Then edit and validate under `~/.dotfiles-workspaces/myfix`. After approval:

```bash
jj -R ~/.dotfiles-workspaces/myfix describe -m "type(scope): description"
jj -R ~/.dotfiles-workspaces/myfix bookmark move main --to @
jj -R ~/.dotfiles-workspaces/myfix git push --bookmark main

# Updating the active working copy is deployment. Inspect its @ first.
jj -R ~/.dotfiles rebase -b @ -o main

jj -R ~/.dotfiles workspace forget myfix
rm -r ~/.dotfiles-workspaces/myfix
```

Never copy workspace files into the active checkout. Publish the reviewed
change, then rebase the active draft onto `main`. If unrelated live work would
conflict, stop instead of forcing deployment.

Jujutsu does not populate Git submodules in additional workspaces. This is fine
for normal dotfile edits; use the live colocated checkout or an independent
colocated clone when changing `tmux-fzf-url` itself.

## Per-host operation

Run these on the target host:

### Loki

| Recipe | Purpose |
|---|---|
| `just sync` | Re-assert Stow, Hypr overrides, package drops, mise, and agent skills |
| `just packages` | Converge repo and AUR packages |
| `just upgrade` | Run `omarchy update`, then upgrade mise tools |
| `just setup` | Fresh provision |

`omarchy update` invokes `loki/sync.sh`. That script retains the one intentional
Git mutation in normal operation:

```bash
git -C ~/.dotfiles submodule update --init --recursive
```

This updates the nested repository checkout, not the superproject history.
Avoid `git pull`, `git commit`, `git rebase`, and Git worktrees in the
superproject after migration.

### Kratos

| Recipe | Purpose |
|---|---|
| `just setup` | Converge brew, mise, and pnpm tools |
| `just upgrade` | Upgrade packages and tools |
| `just upgrade-macos` | Install macOS updates and restart |
| `just audit` | Report current brew/mise state |

## Fresh bootstrap

Git remains the bootstrap tool because jj is installed from the repository's
mise configuration:

```bash
git clone https://github.com/trucke/dotfiles.git ~/.dotfiles
# run the host setup; it installs jj and initializes colocation
```

After SSH keys are registered:

```bash
jj -R ~/.dotfiles git remote set-url origin git@github.com:trucke/dotfiles.git
```

## Deploying this skill

The source is `share/agents/skills/run-dotfiles/`. `share/bin/link-agent-skills`
stows it to `~/.agents/skills/` and bridges it into `~/.claude/skills/`. It runs
as part of Loki sync and Kratos stow.

## Guardrails and gotchas

- **Public repo:** never add secrets, keys, tokens, private hostnames, or private
  infrastructure data.
- **Automatic snapshotting:** jj records unignored files in `@`; inspect
  `jj status` and `jj diff` before moving `main`.
- **No implicit publication:** `jj describe` does not publish. Moving `main` and
  pushing it are explicit, user-requested actions.
- **Fetch is not pull:** after `jj git fetch`, rebase `@` onto updated `main`.
- **The active checkout is deployment:** rebasing it can change live symlink
  targets. Inspect `@` first.
- **Submodules are Git-only:** jj preserves the gitlink but does not manage or
  populate it.
- **Operation recovery:** inspect `jj op log`; use `jj undo` or `jj op restore`
  deliberately. These operations can also update the live working copy.
- **Confirming just recipes:** `just --dry-run` can still prompt for recipes with
  `[confirm(...)]`; redirect stdin from `/dev/null` in automation.

## Troubleshooting

| Symptom | Action |
|---|---|
| Not a jj repo | `cd ~/.dotfiles && jj git init --git-repo=. .` |
| `main` does not track origin | `jj bookmark track main --remote=origin` |
| Working copy is not based on `main` | Review `jj log`, then `jj rebase -b @ -o main` |
| `main` is conflicted | Inspect `jj bookmark list`; move it to the intended revision |
| Workspace is stale | Run `jj workspace update-stale` in that workspace |
| Submodule missing in extra workspace | Expected; validate it from the live colocated checkout |
| Stow reports an existing target | The path points elsewhere; resolve explicitly before real Stow |
