echo -e "Unblocking wifi...\n"
rfkill unblock wifi
rfkill list wifi

echo -e "Unblocking bluetooth...\n"
rfkill unblock bluetooth
rfkill list bluetooth
