#!/usr/bin/env bash
#
# kratos fresh-box setup — run ON the Mac mini as the admin user (NOT root)
# after a clean macOS install and account creation.
#
# It configures system-level defaults that `just bootstrap` can't (hostname,
# network, power/restart behavior, Remote Login), then hands off to
# `just bootstrap` for package/dotfile provisioning. sudo is used per-command
# (you'll be prompted).
#
# Interactive steps that can't be scripted (NetBird SSO, agent logins, FileVault
# recovery key) are printed at the end.

set -euo pipefail

# --- config (edit to taste) ------------------------------------------------
HOST_NAME="kratos"
TIMEZONE="Europe/Berlin"                 # `sudo systemsetup -listtimezones`

# Static IP is OPTIONAL — access is via NetBird regardless. Leave STATIC_IP
# empty to keep DHCP. Find the service name with:
#   networksetup -listallnetworkservices
NET_SERVICE="Ethernet"
STATIC_IP=""                             # e.g. 192.168.1.50
SUBNET_MASK="255.255.255.0"
ROUTER=""                                # e.g. 192.168.1.1
DNS_SERVERS="1.1.1.1 9.9.9.9"

DOTFILES="${HOME}/.dotfiles"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run as the admin user, not root (Homebrew refuses root)." >&2
  exit 1
fi

echo "=== kratos fresh-box setup ==="

# Prime sudo once so the run doesn't prompt repeatedly.
sudo -v

# --- hostname --------------------------------------------------------------
echo "--- hostname -> ${HOST_NAME}"
sudo scutil --set ComputerName "${HOST_NAME}"
sudo scutil --set HostName "${HOST_NAME}"
sudo scutil --set LocalHostName "${HOST_NAME}"

# --- timezone + network time -----------------------------------------------
echo "--- timezone -> ${TIMEZONE}, network time on"
sudo systemsetup -settimezone "${TIMEZONE}" >/dev/null 2>&1 || true
sudo systemsetup -setusingnetworktime on >/dev/null 2>&1 || true

# --- Remote Login (SSH) ----------------------------------------------------
echo "--- enable Remote Login (SSH)"
sudo systemsetup -setremotelogin on

# --- headless-server power behavior ----------------------------------------
# Never sleep; wake on network; auto-restart after power loss / freeze.
# NOTE: with FileVault ON, an unattended reboot stops at the unlock screen —
# power-loss recovery is not fully headless (expected trade-off for encryption).
echo "--- power: never sleep, wake-on-LAN, auto-restart on power loss/freeze"
sudo pmset -a sleep 0 displaysleep 0 disksleep 0
sudo pmset -a womp 1
sudo pmset -a autorestart 1
sudo systemsetup -setrestartpowerfailure on >/dev/null 2>&1 || true
sudo systemsetup -setrestartfreeze on >/dev/null 2>&1 || true

# --- optional static IP ----------------------------------------------------
if [[ -n "${STATIC_IP}" && -n "${ROUTER}" ]]; then
  echo "--- static IP ${STATIC_IP} on '${NET_SERVICE}'"
  sudo networksetup -setmanual "${NET_SERVICE}" "${STATIC_IP}" "${SUBNET_MASK}" "${ROUTER}"
  # shellcheck disable=SC2086
  sudo networksetup -setdnsservers "${NET_SERVICE}" ${DNS_SERVERS}
else
  echo "--- static IP: skipped (DHCP; access is via NetBird)"
fi

# --- Homebrew + just -------------------------------------------------------
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  echo "--- installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
command -v just >/dev/null 2>&1 || brew install just

# --- provision (dotfiles, packages, tools, hardening, theme) ---------------
echo "--- provisioning: just bootstrap"
( cd "${DOTFILES}/kratos" && just bootstrap )

echo "--- SSH keys (generate per convention; register the printed pubkeys)"
( cd "${DOTFILES}/kratos" && just ssh-keys )

# --- remaining interactive steps -------------------------------------------
cat <<'EOF'

=== setup complete — remaining INTERACTIVE steps ===
  1. Register the generated pubkeys: github (GitHub settings),
       net (the other machine's authorized_keys)
  2. From Proton Pass, install into ~/.ssh (chmod 600):
       - shared keys: hlx-admin  roomvibes  rv-edgeplayer  rv-edgeplayer-sync
       - host config: -> ~/.ssh/config.d/hosts.conf
  3. netbird up                       # SSO login (then you can disconnect the display)
  4. just -f ~/.dotfiles/kratos/justfile podman-init
  5. sudo fdesetup enable             # FileVault — SAVE the recovery key
  6. Agents: codex; claude; cursor-agent; opencode  # /connect ; pi  # /login ; t3
  7. t3 serve --host "$(netbird status | awk '/NetBird IP:/{split($3,a,"/");print a[1]}')"
  8. just -f ~/.dotfiles/kratos/justfile audit
EOF
