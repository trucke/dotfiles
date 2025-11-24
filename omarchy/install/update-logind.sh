#!/usr/bin/env bash

set -e

# Backup & uncomment the three lid switch lines
sudo cp /etc/systemd/logind.conf{,.backup-$(date +%s)}
sudo sed -i 's/^#\?HandleLidSwitch=/HandleLidSwitch=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchExternalPower=/HandleLidSwitchExternalPower=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?HandleLidSwitchDocked=/HandleLidSwitchDocked=/' /etc/systemd/logind.conf
sudo sed -i 's/^#\?LidSwitchIgnoreInhibited=/LidSwitchIgnoreInhibited=/' /etc/systemd/logind.conf

echo "Updated logind.conf. Please reboot the system."
