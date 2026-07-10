#!/usr/bin/env bash
#
# kratos hardening — macOS security hardening for a HEADLESS remote dev box.
#
# Derived from privacy.sexy (https://privacy.sexy). Trimmed to what matters on a
# headless box: dropped desktop-app cache clears, GUI cosmetics, history wipes,
# and telemetry env-appends (those live in share/shell/env).
#
# NOTE: Remote Login (SSH) is intentionally LEFT ENABLED — kratos is reached
# only over SSH via NetBird. Never run `systemsetup -setremotelogin off` here.

set -euo pipefail

# Re-exec as root if needed.
if [ "${EUID}" -ne 0 ]; then
    script_path=$([[ "$0" = /* ]] && echo "$0" || echo "$PWD/${0#./}")
    exec sudo "${script_path}"
fi

echo '=== kratos macOS hardening ==='

# --- Time & login ----------------------------------------------------------
echo '--- Enable network time; disable auto-login'
sysadminctl -automaticTime on 2>/dev/null || true
sysadminctl -autologin off 2>/dev/null || true

# --- Application firewall ---------------------------------------------------
# Intentionally kept OFF. kratos is a headless server reached only over NetBird's
# ACL'd WireGuard mesh (SSH-key-only auth, FileVault at rest), and services bind
# to specific interfaces (e.g. t3 serve -> the NetBird IP). The macOS application
# firewall + stealth mode drop incoming connections to those served processes
# (t3 serve, podman) with no real benefit here — NetBird + per-service bind
# addresses govern exposure. Disabled explicitly so a prior run doesn't linger.
echo '--- Application firewall left OFF (NetBird-fronted server)'
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off 2>/dev/null || true
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off 2>/dev/null || true
defaults write /Library/Preferences/com.apple.alf globalstate -int 0

# --- Disable insecure / unused network services ----------------------------
echo '--- Disable telnet, TFTP, Bonjour multicast advertising'
launchctl disable system/com.apple.telnetd 2>/dev/null || true
launchctl disable system/com.apple.tftpd 2>/dev/null || true
defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true

echo '--- Disable printer sharing and remote printer administration'
cupsctl --no-share-printers 2>/dev/null || true
cupsctl --no-remote-any 2>/dev/null || true
cupsctl --no-remote-admin 2>/dev/null || true

# --- Guest access ----------------------------------------------------------
echo '--- Disable guest login and guest file sharing (SMB/AFP)'
defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false
defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
if command -v sysadminctl &>/dev/null; then
    sysadminctl -guestAccount off 2>/dev/null || true
    sysadminctl -smbGuestAccess off 2>/dev/null || true
    sysadminctl -afpGuestAccess off 2>/dev/null || true
fi

echo '=== hardening applied ✓ ==='
