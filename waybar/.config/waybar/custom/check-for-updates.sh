#!/usr/bin/env bash

# Get the number of available updates
update_count=$(paru -Qu 2>/dev/null | wc -l)

if [ "$update_count" -eq 0 ]; then
    # No updates available
    jq --unbuffered --compact-output --null-input \
        --arg text "" \
        --arg tooltip "System is up to date" \
        --arg alt "updated" \
        --arg class "updated" \
        '{"text": $text, "alt": $alt, "tooltip": $tooltip, "class": $class}'
else
    # Updates available
    update_list=$(paru -Qu 2>/dev/null)
    tooltip="${update_count} update(s) available:"$'\r'"${update_list}"
    
    jq --unbuffered --compact-output --null-input \
        --arg text "$update_count" \
        --arg tooltip "$tooltip" \
        --arg class "pending-updates" \
        --arg alt "pending-updates" \
        '{"text": $text, "alt": $alt, "tooltip": $tooltip, "class": $class}'
fi
