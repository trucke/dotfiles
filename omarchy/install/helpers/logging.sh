stop_install_log() {
    if [[ -n ${OMARCHY_INSTALL_LOG_FILE:-} ]]; then
        OMARCHY_END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
        echo "=== Omarchy Installation Completed: $OMARCHY_END_TIME ===" >>"$OMARCHY_INSTALL_LOG_FILE"
        echo "" >>"$OMARCHY_INSTALL_LOG_FILE"
        echo "=== Installation Time Summary ===" >>"$OMARCHY_INSTALL_LOG_FILE"

        if [ -f "/var/log/archinstall/install.log" ]; then
            ARCHINSTALL_START=$(grep -m1 '^\[' /var/log/archinstall/install.log 2>/dev/null | sed 's/^\[\([^]]*\)\].*/\1/' || true)
            ARCHINSTALL_END=$(grep 'Installation completed without any errors' /var/log/archinstall/install.log 2>/dev/null | sed 's/^\[\([^]]*\)\].*/\1/' || true)

            if [ -n "$ARCHINSTALL_START" ] && [ -n "$ARCHINSTALL_END" ]; then
                ARCH_START_EPOCH=$(date -d "$ARCHINSTALL_START" +%s)
                ARCH_END_EPOCH=$(date -d "$ARCHINSTALL_END" +%s)
                ARCH_DURATION=$((ARCH_END_EPOCH - ARCH_START_EPOCH))

                ARCH_MINS=$((ARCH_DURATION / 60))
                ARCH_SECS=$((ARCH_DURATION % 60))

                echo "Archinstall: ${ARCH_MINS}m ${ARCH_SECS}s" >>"$OMARCHY_INSTALL_LOG_FILE"
            fi
        fi

        if [ -n "$OMARCHY_START_TIME" ]; then
            OMARCHY_START_EPOCH=$(date -d "$OMARCHY_START_TIME" +%s)
            OMARCHY_END_EPOCH=$(date -d "$OMARCHY_END_TIME" +%s)
            OMARCHY_DURATION=$((OMARCHY_END_EPOCH - OMARCHY_START_EPOCH))

            OMARCHY_MINS=$((OMARCHY_DURATION / 60))
            OMARCHY_SECS=$((OMARCHY_DURATION % 60))

            echo "Omarchy:     ${OMARCHY_MINS}m ${OMARCHY_SECS}s" >>"$OMARCHY_INSTALL_LOG_FILE"

            if [ -n "$ARCH_DURATION" ]; then
                TOTAL_DURATION=$((ARCH_DURATION + OMARCHY_DURATION))
                TOTAL_MINS=$((TOTAL_DURATION / 60))
                TOTAL_SECS=$((TOTAL_DURATION % 60))
                echo "Total:       ${TOTAL_MINS}m ${TOTAL_SECS}s" >>"$OMARCHY_INSTALL_LOG_FILE"
            fi
        fi
        echo "=================================" >>"$OMARCHY_INSTALL_LOG_FILE"

        echo "Rebooting system..." >>"$OMARCHY_INSTALL_LOG_FILE"
    fi
}

start_install_log() {
    sudo rm "${OMARCHY_INSTALL_LOG_FILE}"
    sudo touch "$OMARCHY_INSTALL_LOG_FILE"
    sudo chmod 666 "$OMARCHY_INSTALL_LOG_FILE"
    export OMARCHY_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== Omarchy Installation Started: $OMARCHY_START_TIME ===" >>"$OMARCHY_INSTALL_LOG_FILE"
}

run_logged() {
    local script="$1"
    export CURRENT_SCRIPT="${script}"
    local trim_script=$(echo "${script}" | sed 's|.*/omarchy/install/||' | sed 's|\.sh$||')

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script" >>"$OMARCHY_INSTALL_LOG_FILE"
    gum style --bold --padding "1 0 0 $PADDING_LEFT" --foreground 6 "Starting: ${trim_script}"

    # Use bash -c to create a clean subshell
    #bash -c "source '$script'" </dev/null >>"$OMARCHY_INSTALL_LOG_FILE" 2>&1
    gum spin --spinner points --padding "0 0 0 $PADDING_LEFT" \
        --title.foreground 8 --title "Running script ..." -- \
        bash -c "source '$script' </dev/null >>'$OMARCHY_INSTALL_LOG_FILE' 2>&1"

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script" >>"$OMARCHY_INSTALL_LOG_FILE"
        log "[OK] Completed: ${trim_script}"
        unset CURRENT_SCRIPT
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)" >>"$OMARCHY_INSTALL_LOG_FILE"
    fi

    return $exit_code
}

log() {
    local padding=${2:-0}
    padding=$(($PADDING_LEFT + $padding))
    local color=${3:-2}
    gum style --padding "0 0 0 ${padding}" --foreground $color "$1"
}

export -f log
