#!/usr/bin/env bash
#
# Dotfiles doctor — health checks and isolated-workspace helper for the live
# host-based dotfiles repository.
#
# Commands:
#   doctor.sh [doctor] [REPO]         full health check (default: $DOTFILES or ~/.dotfiles)
#   doctor.sh validate REPO           checks without fetching origin
#   doctor.sh workspace NAME [REPO]   create ~/.dotfiles-workspaces/NAME from main
#
# Exit status: 0 = all hard checks passed, 1 = a hard check failed.
# Stow conflicts and unpublished work are warnings.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="${DOTFILES:-$HOME/.dotfiles}"

SHARE_MAP=(
  "zsh:${HOME}"
  "config:${HOME}/.config"
  "bin:${HOME}/.local/bin"
  "ssh:${HOME}/.ssh"
  "pi:${HOME}/.pi/agent"
)

if [ -t 1 ]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; Z=$'\e[0m'
else B=; G=; Y=; R=; D=; Z=; fi
FAILS=0; WARNS=0
hdr()  { printf '\n%s== %s ==%s\n' "$B" "$1" "$Z"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
warn() { printf '  %s! %s%s\n' "$Y" "$1" "$Z"; WARNS=$((WARNS+1)); }
fail() { printf '  %s✗ %s%s\n' "$R" "$1" "$Z"; FAILS=$((FAILS+1)); }
info() { printf '  %s%s%s\n' "$D" "$1" "$Z"; }

count_revisions() {
  local repo="$1" revset="$2"
  jj -R "$repo" log -r "$revset" --no-graph -T 'commit_id ++ "\n"' 2>/dev/null | wc -l | tr -d ' '
}

check_tools() {
  hdr "tooling"
  local t
  for t in jj git stow just; do
    if command -v "$t" >/dev/null 2>&1; then
      ok "$t $("$t" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9.]+' | head -1)"
    else
      fail "$t not found (required)"
    fi
  done
  command -v shellcheck >/dev/null 2>&1 && ok "shellcheck (optional) present" || warn "shellcheck not found — script linting skipped"
}

check_repo() {
  local repo="$1" remote="${2:-1}"
  hdr "repo @ $repo"
  if ! jj -R "$repo" root >/dev/null 2>&1; then
    fail "not a Jujutsu repo — initialize with 'jj git init --git-repo=. .'"
    return
  fi

  local colocated workspace_root git_root
  colocated="$(jj -R "$repo" git colocation status 2>/dev/null || true)"
  workspace_root="$(jj -R "$repo" root 2>/dev/null)"
  git_root="$(jj -R "$repo" git root 2>/dev/null || true)"
  if printf '%s' "$colocated" | grep -q 'currently colocated'; then
    ok "colocated Jujutsu/Git workspace"
  elif [[ -n "$git_root" && "$git_root" != "$workspace_root"/* ]]; then
    info "linked jj workspace (Git colocation belongs to the primary workspace)"
  else
    warn "workspace is not colocated; the Git submodule workflow requires colocation"
  fi

  local current
  current="$(jj -R "$repo" log -r @ --no-graph -T 'change_id.short() ++ " " ++ commit_id.short() ++ " " ++ if(empty, "(empty) ", "") ++ description.first_line() ++ "\n"' 2>/dev/null)"
  info "working copy: ${current:-unknown}"

  local changed
  changed="$(jj -R "$repo" diff -r @ --summary 2>/dev/null | wc -l | tr -d ' ')"
  [ "$changed" -eq 0 ] && ok "working-copy change is empty" || warn "$changed changed file(s) in @ — 'jj -R $repo status'"

  local conflicts
  conflicts="$(jj -R "$repo" resolve --list 2>/dev/null | wc -l | tr -d ' ')"
  [ "$conflicts" -eq 0 ] && ok "no file conflicts" || fail "$conflicts unresolved file conflict(s)"

  if [ "$remote" = "1" ]; then
    jj -R "$repo" git fetch --remote origin --quiet 2>/dev/null || warn "could not fetch origin"
  fi

  local main_id origin_id
  main_id="$(jj -R "$repo" log -r main --no-graph -T 'commit_id ++ "\n"' 2>/dev/null || true)"
  origin_id="$(jj -R "$repo" log -r 'main@origin' --no-graph -T 'commit_id ++ "\n"' 2>/dev/null || true)"
  if [ "$(printf '%s\n' "$main_id" | grep -c .)" -ne 1 ]; then
    fail "local main bookmark is missing or conflicted"
  elif [ "$(printf '%s\n' "$origin_id" | grep -c .)" -ne 1 ]; then
    fail "main@origin bookmark is missing or conflicted"
  else
    local ahead behind
    ahead="$(count_revisions "$repo" 'main@origin..main')"
    behind="$(count_revisions "$repo" 'main..main@origin')"
    info "main:        ${main_id:0:12}"
    info "main@origin: ${origin_id:0:12}"
    if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
      ok "main is synchronized with origin"
    else
      warn "main is ahead by $ahead, behind by $behind"
    fi
  fi

  if jj -R "$repo" bookmark list --tracked main --remote origin 2>/dev/null | grep -q '^main:'; then
    ok "main tracks main@origin"
  else
    warn "main does not track main@origin — 'jj -R $repo bookmark track main --remote=origin'"
  fi

  local parent_id
  parent_id="$(jj -R "$repo" log -r @- --no-graph -T 'commit_id ++ "\n"' 2>/dev/null || true)"
  if [ -n "$main_id" ] && [ "$parent_id" = "$main_id" ]; then
    ok "working copy is based directly on main"
  else
    warn "working copy is not based directly on main — review, then 'jj -R $repo rebase -b @ -o main'"
  fi

  local workspace_count
  workspace_count="$(jj -R "$repo" workspace list 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$workspace_count" -le 1 ]; then
    info "one active workspace"
  elif [ "$remote" = "1" ]; then
    warn "$workspace_count active workspaces — 'jj -R $repo workspace list'"
  else
    info "$workspace_count active workspaces"
  fi
}

check_submodules() {
  local repo="$1"
  hdr "Git compatibility"
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    info "no colocated Git worktree here; submodule check skipped"
    return
  fi
  local status
  status="$(git -C "$repo" submodule status --recursive 2>/dev/null || true)"
  if [ -z "$status" ]; then
    info "no Git submodules"
  elif printf '%s\n' "$status" | grep -qE '^[-+U]'; then
    warn "submodule is uninitialized, modified, or conflicted"
    printf '%s\n' "$status" | sed 's/^/      /'
  else
    ok "Git submodule initialized at the recorded revision"
  fi
}

HOST_DIR=""
detect_host() {
  local repo="$1" h
  h="$(hostname -s 2>/dev/null || hostname 2>/dev/null)"
  h="$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')"
  hdr "host"
  local hosts=() d
  for d in "$repo"/*/justfile; do [ -e "$d" ] && hosts+=("$(basename "$(dirname "$d")")"); done
  info "host dirs in repo: ${hosts[*]:-none}"
  if [ -n "$h" ] && [ -f "$repo/$h/justfile" ]; then
    ok "this machine -> $h/  (hostname: $h)"
    HOST_DIR="$h"
  else
    warn "hostname '$h' has no host dir with a justfile — checking all hosts"
    HOST_DIR=""
  fi
}

check_just() {
  local repo="$1" host="$2"
  hdr "just recipes"
  local files=() f
  if [ -n "$host" ] && [ -f "$repo/$host/justfile" ]; then
    files=("$repo/$host/justfile")
  else
    for f in "$repo"/*/justfile; do [ -e "$f" ] && files+=("$f"); done
  fi
  [ "${#files[@]}" -eq 0 ] && { info "no justfile found under $repo/*/"; return; }
  for f in "${files[@]}"; do
    local rel n
    rel="${f#"$repo"/}"
    if just --justfile "$f" --list >/dev/null 2>&1; then
      n="$(just --justfile "$f" --summary 2>/dev/null | wc -w | tr -d ' ')"
      ok "$rel parses ($n recipes)"
    else
      fail "$rel does NOT parse — 'just --justfile $f --list'"
    fi
  done
}

check_shellcheck() {
  local repo="$1"
  hdr "shell scripts"
  command -v shellcheck >/dev/null 2>&1 || { info "shellcheck absent — skipped"; return; }
  local scripts=() f
  while IFS= read -r f; do scripts+=("$f"); done < <(find "$repo" -type f -name '*.sh' -not -path '*/.git/*' -not -path '*/.jj/*' 2>/dev/null | sort)
  while IFS= read -r f; do
    head -1 "$f" 2>/dev/null | grep -qE '^#!.*(bash|sh)$|^#!.*/env (bash|sh)' && scripts+=("$f")
  done < <(find "$repo" -type f -path '*/bin/*' -not -name '*.sh' -not -path '*/.git/*' -not -path '*/.jj/*' 2>/dev/null | sort)
  [ "${#scripts[@]}" -eq 0 ] && { info "no shell scripts found"; return; }
  local bad=0
  for f in "${scripts[@]}"; do
    if ! shellcheck -S warning "$f" >/dev/null 2>&1; then
      bad=$((bad+1))
      warn "${f#"$repo"/} has shellcheck warnings — 'shellcheck ${f#"$repo"/}'"
    fi
  done
  [ "$bad" -eq 0 ] && ok "${#scripts[@]} script(s) clean at -S warning"
}

check_stow() {
  local repo="$1"
  hdr "stow (share/ dry-run restow)"
  [ -d "$repo/share" ] || { info "no share/ dir"; return; }
  local entry
  for entry in "${SHARE_MAP[@]}"; do
    local pkg="${entry%%:*}" target="${entry#*:}"
    [ -d "$repo/share/$pkg" ] || { info "$pkg: not a package here"; continue; }
    if [ ! -d "$target" ]; then info "$pkg -> $target (target missing; would be created on real stow)"; continue; fi
    local out
    out="$(stow -n -v -R --dir="$repo/share" --target="$target" "$pkg" 2>&1)"
    if printf '%s' "$out" | grep -qiE 'conflict|existing target|cannot stow'; then
      warn "$pkg -> $target: CONFLICT (non-symlink in the way, or points elsewhere)"
      printf '%s\n' "$out" | grep -iE 'conflict|existing' | head -3 | sed 's/^/      /'
    else
      ok "$pkg -> $target: no conflicts"
    fi
  done
}

do_doctor() {
  local repo="${1:-$DEFAULT_REPO}" remote="${2:-1}"
  repo="$(cd "$repo" 2>/dev/null && pwd)" || { echo "no such repo: ${1:-$DEFAULT_REPO}" >&2; exit 1; }
  printf '%sdotfiles doctor%s  %s\n' "$B" "$Z" "$repo"
  check_tools
  check_repo "$repo" "$remote"
  check_submodules "$repo"
  detect_host "$repo"
  check_just "$repo" "$HOST_DIR"
  check_shellcheck "$repo"
  local live_repo
  live_repo="$(cd "$DEFAULT_REPO" 2>/dev/null && pwd || true)"
  if [ "$repo" = "$live_repo" ]; then
    check_stow "$repo"
  else
    hdr "stow"
    info "live-target check skipped for an isolated workspace"
  fi
  hdr "summary"
  if [ "$FAILS" -gt 0 ]; then
    printf '  %s✗%s %s hard failure(s), %s warning(s)\n' "$R" "$Z" "$FAILS" "$WARNS"
    exit 1
  elif [ "$WARNS" -gt 0 ]; then
    printf '  %s!%s 0 failures, %s warning(s) — review above\n' "$Y" "$Z" "$WARNS"
  else
    ok "all checks passed"
  fi
}

do_workspace() {
  local name="${1:-}" repo="${2:-$DEFAULT_REPO}"
  [ -n "$name" ] || { echo "usage: doctor.sh workspace NAME [REPO]" >&2; exit 2; }
  repo="$(cd "$repo" 2>/dev/null && pwd)" || { echo "no such repo: ${2:-$DEFAULT_REPO}" >&2; exit 1; }
  local ws="${HOME}/.dotfiles-workspaces/${name}"
  [ ! -e "$ws" ] || { echo "workspace path already exists: $ws" >&2; exit 1; }
  mkdir -p "${HOME}/.dotfiles-workspaces"
  jj -R "$repo" git fetch --remote origin
  jj -R "$repo" workspace add --name "$name" -r main "$ws"
  cat <<EOF

Workspace ready: $ws  (change based on main)

Use isolation only when a change must not affect the live Stow source:

  1. edit files in:  $ws
  2. validate:       "$SKILL_DIR/doctor.sh" validate "$ws"
  3. describe:       jj -R "$ws" describe -m "type(scope): description"
  4. publish:        jj -R "$ws" bookmark move main --to @
                     jj -R "$ws" git push --bookmark main
  5. deploy live:    jj -R "$repo" rebase -b @ -o main
  6. forget:         jj -R "$repo" workspace forget "$name"
                     rm -r "$ws"

The Git submodule is not populated in additional jj workspaces. Use the live
colocated checkout or an independent clone when changing tmux-fzf-url itself.
EOF
}

case "${1:-doctor}" in
  doctor)    do_doctor "${2:-$DEFAULT_REPO}" 1 ;;
  validate)  [ -n "${2:-}" ] || { echo "usage: doctor.sh validate REPO" >&2; exit 2; }
             do_doctor "$2" 0 ;;
  workspace) do_workspace "${2:-}" "${3:-$DEFAULT_REPO}" ;;
  -h|--help|help) grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *)         do_doctor "$1" 1 ;;
esac
