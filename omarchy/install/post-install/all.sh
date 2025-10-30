run_logged $OMARCHY_INSTALL/post-install/pacman.sh
run_logged $OMARCHY_INSTALL/post-install/restart-services.sh
source $OMARCHY_INSTALL/post-install/allow-reboot.sh
source $OMARCHY_INSTALL/post-install/finished.sh
