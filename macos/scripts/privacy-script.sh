#!/usr/bin/env bash
# https://privacy.sexy — v0.13.8 — Wed, 04 Feb 2026 08:40:27 GMT
if [ "$EUID" -ne 0 ]; then
    script_path=$([[ "$0" = /* ]] && echo "$0" || echo "$PWD/${0#./}")
    sudo "$script_path" || (
        echo 'Administrator privileges are required.'
        exit 1
    )
    exit 0
fi

# ----------------------------------------------------------
# ---------------------Clear DNS cache----------------------
# ----------------------------------------------------------
echo '--- Clear DNS cache'
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------------------Clear inactive memory-------------------
# ----------------------------------------------------------
echo '--- Clear inactive memory'
sudo purge
# ----------------------------------------------------------

# ----------------------------------------------------------
# --Disable automatic storage of documents in iCloud Drive--
# ----------------------------------------------------------
echo '--- Disable automatic storage of documents in iCloud Drive'
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# ----------------------------------------------------------

# Disable personalized advertisements and identifier tracking
echo '--- Disable personalized advertisements and identifier tracking'
defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.AdLib forceLimitAdTracking -bool true
# ----------------------------------------------------------

# ----------------------------------------------------------
# --------------------Clear bash history--------------------
# ----------------------------------------------------------
echo '--- Clear bash history'
rm -f ~/.bash_history
# ----------------------------------------------------------

# ----------------------------------------------------------
# --------------------Clear zsh history---------------------
# ----------------------------------------------------------
echo '--- Clear zsh history'
rm -f ~/.zsh_history
# ----------------------------------------------------------

# ----------------------------------------------------------
# -------------------Clear Mail app logs--------------------
# ----------------------------------------------------------
echo '--- Clear Mail app logs'
# Clear directory contents: "$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
glob_pattern="$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/*"
rm -rfv $glob_pattern
# ----------------------------------------------------------

# ----------------------------------------------------------
# --------------Clear system maintenance logs---------------
# ----------------------------------------------------------
echo '--- Clear system maintenance logs'
# Delete files matching pattern: "/private/var/log/daily.out"
glob_pattern="/private/var/log/daily.out"
sudo rm -fv $glob_pattern
# Delete files matching pattern: "/private/var/log/weekly.out"
glob_pattern="/private/var/log/weekly.out"
sudo rm -fv $glob_pattern
# Delete files matching pattern: "/private/var/log/monthly.out"
glob_pattern="/private/var/log/monthly.out"
sudo rm -fv $glob_pattern
# ----------------------------------------------------------

# ----------------------------------------------------------
# --------------------Clear Adobe cache---------------------
# ----------------------------------------------------------
echo '--- Clear Adobe cache'
sudo rm -rfv ~/Library/Application\ Support/Adobe/Common/Media\ Cache\ Files/* &>/dev/null
# ----------------------------------------------------------

# ----------------------------------------------------------
# -------------------Clear Dropbox cache--------------------
# ----------------------------------------------------------
echo '--- Clear Dropbox cache'
if [ -d "~/Dropbox/.dropbox.cache" ]; then
    sudo rm -rfv ~/Dropbox/.dropbox.cache/* &>/dev/null
fi
# ----------------------------------------------------------

# ----------------------------------------------------------
# -----------Clear Google Drive File Stream cache-----------
# ----------------------------------------------------------
echo '--- Clear Google Drive File Stream cache'
killall "Google Drive File Stream"
rm -rfv ~/Library/Application\ Support/Google/DriveFS/[0-9a-zA-Z]*/content_cache &>/dev/null
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------------------Clear iOS photo cache-------------------
# ----------------------------------------------------------
echo '--- Clear iOS photo cache'
rm -rf ~/Pictures/iPhoto\ Library/iPod\ Photo\ Cache/*
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------Disable participation in Siri data collection-------
# ----------------------------------------------------------
echo '--- Disable participation in Siri data collection'
defaults write com.apple.assistant.support 'Siri Data Sharing Opt-In Status' -int 2
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------------Disable the insecure TFTP service-------------
# ----------------------------------------------------------
echo '--- Disable the insecure TFTP service'
sudo launchctl disable 'system/com.apple.tftpd'
# ----------------------------------------------------------

# ----------------------------------------------------------
# -------------Disable insecure telnet protocol-------------
# ----------------------------------------------------------
echo '--- Disable insecure telnet protocol'
sudo launchctl disable system/com.apple.telnetd
# ----------------------------------------------------------

# ----------------------------------------------------------
# ----Disable local printer sharing with other computers----
# ----------------------------------------------------------
echo '--- Disable local printer sharing with other computers'
cupsctl --no-share-printers
# ----------------------------------------------------------

# Disable printing from external addresses, including the internet
echo '--- Disable printing from external addresses, including the internet'
cupsctl --no-remote-any
# ----------------------------------------------------------

# ----------------------------------------------------------
# ----------Disable remote printer administration-----------
# ----------------------------------------------------------
echo '--- Disable remote printer administration'
cupsctl --no-remote-admin
# ----------------------------------------------------------

# ----------------------------------------------------------
# --------------------Remove Guest User---------------------
# ----------------------------------------------------------
echo '--- Remove Guest User'
if ! command -v 'sysadminctl' &>/dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -deleteUser Guest
fi
if ! command -v 'fdesetup' &>/dev/null; then
    echo 'Skipping because "fdesetup" is not found.'
else
    sudo fdesetup remove -user Guest
fi
if ! command -v 'dscl' &>/dev/null; then
    echo 'Skipping because "dscl" is not found.'
else
    sudo dscl . delete /Users/Guest
fi
# ----------------------------------------------------------

# ----------------------------------------------------------
# -------------Disable online spell correction--------------
# ----------------------------------------------------------
echo '--- Disable online spell correction'
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------Disable display of recent applications on Dock------
# ----------------------------------------------------------
echo '--- Disable display of recent applications on Dock'
defaults write com.apple.dock show-recents -bool false
# ----------------------------------------------------------

# ----------------------------------------------------------
# ------Disable date and time in screenshot filenames-------
# ----------------------------------------------------------
echo '--- Disable date and time in screenshot filenames'
defaults write 'com.apple.screencapture' 'include-date' -bool false
killall SystemUIServer
# ----------------------------------------------------------

# ----------------------------------------------------------
# ---------------Disable guest account login----------------
# ----------------------------------------------------------
echo '--- Disable guest account login'
sudo defaults write '/Library/Preferences/com.apple.loginwindow' 'GuestEnabled' -bool NO
if ! command -v 'sysadminctl' &>/dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -guestAccount off
fi
# ----------------------------------------------------------

# ----------------------------------------------------------
# -----------Disable guest file sharing over SMB------------
# ----------------------------------------------------------
echo '--- Disable guest file sharing over SMB'
sudo defaults write '/Library/Preferences/SystemConfiguration/com.apple.smb.server' 'AllowGuestAccess' -bool NO
if ! command -v 'sysadminctl' &>/dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -smbGuestAccess off
fi
# ----------------------------------------------------------

# ----------------------------------------------------------
# -----------Disable guest file sharing over AFP------------
# ----------------------------------------------------------
echo '--- Disable guest file sharing over AFP'
sudo defaults write '/Library/Preferences/com.apple.AppleFileServer' 'guestAccess' -bool NO
if ! command -v 'sysadminctl' &>/dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -afpGuestAccess off
fi
sudo killall -HUP AppleFileServer
# ----------------------------------------------------------

# ----------------------------------------------------------
# ---------------Enable application firewall----------------
# ----------------------------------------------------------
echo '--- Enable application firewall'
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo defaults write /Library/Preferences/com.apple.alf globalstate -bool true
defaults write com.apple.security.firewall EnableFirewall -bool true
# ----------------------------------------------------------

# ----------------------------------------------------------
# -----------------Enable firewall logging------------------
# ----------------------------------------------------------
echo '--- Enable firewall logging'
/usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on
sudo defaults write /Library/Preferences/com.apple.alf loggingenabled -bool true
# ----------------------------------------------------------

# ----------------------------------------------------------
# -------------------Enable stealth mode--------------------
# ----------------------------------------------------------
echo '--- Enable stealth mode'
/usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -bool true
defaults write com.apple.security.firewall EnableStealthMode -bool true
# ----------------------------------------------------------

echo 'Your privacy and security is now hardened 🎉💪'
echo 'Press any key to exit.'
read -n 1 -s
