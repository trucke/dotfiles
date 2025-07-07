#!/usr/bin/env bash

run() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

gum style \
        --foreground="#ff79c6" \
        --border="double" \
        --align="left" \
        --width=80 \
        --margin="1 2" \
        --padding="2 4" \
        "Setup and configure fingerprint sensor" \

gum confirm "Ready to start the setup?" || exit 0

run "Install necessary package..." paru -S --noconfirm fprint fwupd

local guid=$(fwupdmgr get-devices | grep -A 6 "fingerprint" | grep guid | awk '{print $3}')
run "Update fingerprint sensor firmware..." fwupdmgr get-updates "$guid" && fwupdmgr update "$guid"

# +--------+------------------------------------+
# | Number | Finger                             |
# +--------+------------------------------------+
# |   1    | Left thumb                         |
# |   2    | Left index finger                  |
# |   3    | Left middle finger                 |
# |   4    | Left ring finger                   |
# |   5    | Left little finger                 |
# |   6    | Right thumb                        |
# |   7    | Right index finger (default)       |
# |   8    | Right middle finger                |
# |   9    | Right ring finger                  |
# |  10    | Right little finger                |
# +--------+------------------------------------+
gum log --time TimeOnly --level info --time.foreground="#50fa7b" \
    "Setup right index finger as first fingerprint."

run "Setting up fingerprint. Keep moving the finger around on sensor until the process completes..." \
    sudo fprintd-enroll "${USER}"

if fprintd-verify; then
    gum log --time TimeOnly --level info --time.foreground="#50fa7b" \
        "Noice. Fingerprint successfully set up."
else
    gum log --time TimeOnly --level error --time.foreground="#ff5555" \
        "Something went wrong. Try to run the script again."
fi
