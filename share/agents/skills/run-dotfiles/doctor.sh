#!/usr/bin/env bash
#
# dotfiles doctor — the harness for driving the host-based dotfiles repo.
#
# This repo is not an app you "launch"; it is deployed with GNU Stow and
# operated through per-host `just` recipes (kratos/ = macOS, loki/ = Arch,
# share/ = common). The two things that actually go wrong are (a) stow symlink
# conflicts and (b) editing on the live checkout instead of a worktree. This
# script surfaces both, read-only, on any machine.
#
# This is a GLOBAL skill (~/.claude/skills/run-dotfiles), so it targets the
# dotfiles repo by path: $DOTFILES, else ~/.dotfiles. Override with an arg.
#
# Commands:
#   doctor.sh [doctor] [REPO]        full read-only health check (default REPO = $DOTFILES or ~/.dotfiles)
#   doctor.sh validate REPO          same checks minus the git-remote compare (use inside a worktree)
#   doctor.sh worktree NAME [REPO]   create ~/.dotfiles-worktrees/NAME from origin/main for a safe edit
#
# Exit status: 0 = all hard checks passed, 1 = a hard check failed
# (missing tool, unparseable justfile). Stow conflicts are WARN, not FAIL —
# they are expected on a machine that is mid-migration.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="${DOTFILES:-$HOME/.dotfiles}"          # global skill -> point at the dotfiles repo

# Shared share/ stow packages -> target dir (relative to $HOME). This mirrors
# the kratos `just stow` recipe, the authoritative shared layout.
SHARE_MAP=(
  "zsh:${HOME}"
  "config:${HOME}/.config"
  "bin:${HOME}/.local/bin"
  "ssh:${HOME}/.ssh"
  "pi:${HOME}/.pi/agent"
)

# --- output helpers --------------------------------------------------------
if [ -t 1 ]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; D=$'\e[2m'; Z=$'\e[0m'
else B=; G=; Y=; R=; D=; Z=; fi
FAILS=0; WARNS=0
hdr()  { printf '\n%s== %s ==%s\n' "$B" "$1" "$Z"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
warn() { printf '  %s! %s%s\n' "$Y" "$1" "$Z"; WARNS=$((WARNS+1)); }
fail() { printf '  %s✗ %s%s\n' "$R" "$1" "$Z"; FAILS=$((FAILS+1)); }
info() { printf '  %s%s%s\n' "$D" "$1" "$Z"; }

# --- checks ----------------------------------------------------------------

check_tools() {
  hdr "tooling"
  for t in git stow just; do
    if command -v "$t" >/dev/null 2>&1; then ok "$t $("$t" --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9.]+' | head -1)"
    else fail "$t not found (required)"; fi
  done
  command -v shellcheck >/dev/null 2>&1 && ok "shellcheck (optional) present" || warn "shellcheck not found — script linting skipped"
}

check_repo() {
  local repo="$1" remote="${2:-1}"
  hdr "repo @ $repo"
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then fail "not a git repo"; return; fi
  local branch head
  branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  head="$(git -C "$repo" log --oneline -1 2>/dev/null)"
  ok "branch: $branch"
  info "HEAD:   $head"
  local dirty; dirty="$(git -C "$repo" status --porcelain | wc -l | tr -d ' ')"
  [ "$dirty" -eq 0 ] && ok "working tree clean" || warn "$dirty uncommitted file(s) — 'git -C $repo status'"
  if [ "$remote" = "1" ]; then
    git -C "$repo" fetch origin --quiet 2>/dev/null || warn "could not fetch origin"
    local behind ahead
    behind="$(git -C "$repo" rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
    ahead="$(git -C "$repo" rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
    info "origin/main: $(git -C "$repo" log --oneline -1 origin/main 2>/dev/null)"
    if [ "$behind" = "0" ] && [ "$ahead" = "0" ]; then ok "in sync with origin/main"
    else warn "behind origin/main by $behind, ahead by $ahead (behind is expected on a live checkout mid-migration)"; fi
  fi
  local wts; wts="$(git -C "$repo" worktree list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')"
  [ "$wts" -eq 0 ] && info "no extra worktrees" || warn "$wts active worktree(s) — 'git -C $repo worktree list'"
}

# Sets global HOST_DIR (empty if no match). Prints its own section to stdout —
# do NOT call inside $(...) or the section vanishes.
HOST_DIR=""
detect_host() {
  local repo="$1" h
  h="$(hostname -s 2>/dev/null || hostname 2>/dev/null)"; h="$(printf '%s' "$h" | tr '[:upper:]' '[:lower:]')"
  hdr "host"
  local hosts=(); for d in "$repo"/*/justfile; do [ -e "$d" ] && hosts+=("$(basename "$(dirname "$d")")"); done
  info "host dirs in repo: ${hosts[*]:-none}"
  if [ -n "$h" ] && [ -f "$repo/$h/justfile" ]; then ok "this machine -> $h/  (hostname: $h)"; HOST_DIR="$h"; return; fi
  warn "hostname '$h' has no host dir with a justfile — checking all hosts"; HOST_DIR=""
}

check_just() {
  local repo="$1" host="$2"
  hdr "just recipes"
  local files=()
  if [ -n "$host" ] && [ -f "$repo/$host/justfile" ]; then files=("$repo/$host/justfile")
  else for f in "$repo"/*/justfile; do [ -e "$f" ] && files+=("$f"); done; fi
  [ "${#files[@]}" -eq 0 ] && { info "no justfile found under $repo/*/"; return; }
  for f in "${files[@]}"; do
    local rel; rel="${f#"$repo"/}"
    if just --justfile "$f" --list >/dev/null 2>&1; then
      local n; n="$(just --justfile "$f" --summary 2>/dev/null | wc -w | tr -d ' ')"
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
  while IFS= read -r f; do scripts+=("$f"); done < <(find "$repo" -type f -name '*.sh' -not -path '*/.git/*' 2>/dev/null | sort)
  # also scan extensionless scripts with a shell shebang under */bin and share/bin
  while IFS= read -r f; do
    head -1 "$f" 2>/dev/null | grep -qE '^#!.*(bash|sh)$|^#!.*/env (bash|sh)' && scripts+=("$f")
  done < <(find "$repo" -type f -path '*/bin/*' -not -name '*.sh' -not -path '*/.git/*' 2>/dev/null | sort)
  [ "${#scripts[@]}" -eq 0 ] && { info "no shell scripts found"; return; }
  local bad=0
  for f in "${scripts[@]}"; do
    if ! shellcheck -S warning "$f" >/dev/null 2>&1; then
      bad=$((bad+1)); warn "${f#"$repo"/} has shellcheck warnings — 'shellcheck ${f#"$repo"/}'"
    fi
  done
  [ "$bad" -eq 0 ] && ok "${#scripts[@]} script(s) clean at -S warning"
}

check_stow() {
  local repo="$1"
  hdr "stow (share/ dry-run restow)"
  [ -d "$repo/share" ] || { info "no share/ dir"; return; }
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
  detect_host "$repo"
  check_just "$repo" "$HOST_DIR"
  check_shellcheck "$repo"
  check_stow "$repo"
  hdr "summary"
  if [ "$FAILS" -gt 0 ]; then fail "$FAILS hard failure(s), $WARNS warning(s)"; exit 1
  elif [ "$WARNS" -gt 0 ]; then warn "0 failures, $WARNS warning(s) — review above"; exit 0
  else ok "all checks passed"; exit 0; fi
}

do_worktree() {
  local name="${1:-}" repo="${2:-$DEFAULT_REPO}"
  [ -n "$name" ] || { echo "usage: doctor.sh worktree NAME [REPO]" >&2; exit 2; }
  repo="$(cd "$repo" 2>/dev/null && pwd)" || { echo "no such repo: ${2:-$DEFAULT_REPO}" >&2; exit 1; }
  local wt="${HOME}/.dotfiles-worktrees/${name}"
  mkdir -p "${HOME}/.dotfiles-worktrees"
  git -C "$repo" fetch origin --quiet 2>/dev/null || true
  git -C "$repo" worktree add -b "feature/${name}" "$wt" origin/main
  cat <<EOF

Worktree ready: $wt  (branch feature/${name}, from origin/main)

Safe-edit workflow — NEVER commit on the live checkout, it would move the
symlink targets out from under a running machine:

  1. edit files in   $wt
  2. validate:       "$SKILL_DIR/doctor.sh" validate "$wt"
  3. commit:         git -C "$wt" add -A && git -C "$wt" commit
  4. publish:        git -C "$wt" push origin feature/${name}:main   # fast-forward onto main
  5. cleanup:        rm -rf "$wt" && git -C "$repo" worktree prune && git -C "$repo" branch -D feature/${name}
EOF
}

# --- dispatch --------------------------------------------------------------
case "${1:-doctor}" in
  doctor)   do_doctor "${2:-$DEFAULT_REPO}" 1 ;;
  validate) [ -n "${2:-}" ] || { echo "usage: doctor.sh validate REPO" >&2; exit 2; }
            do_doctor "$2" 0 ;;
  worktree) do_worktree "${2:-}" "${3:-$DEFAULT_REPO}" ;;
  -h|--help|help) grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
  *)        do_doctor "$1" 1 ;;   # bare path arg = doctor that repo
esac
