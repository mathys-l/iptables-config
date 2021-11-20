#!/bin/bash

################################################################
# project: 'iptables-config'                                   #
# project-author: 'mathys-l; Erglug'                           #
# project-version: '0.1.0'                                     #
# license: 'GNU Affero General Public License v3.0'            #
# license-notice: 'https://iptables-config.me/LICENSE'         #
# github-link: 'https://github.com/mathys-l/Iptables-config'   #
################################################################

clear

# check run in sudo
if [ "$EUID" -ne 0 ]; then
   echo "Please run script with sudo"
   exit 1
fi

# check for whiptail
if ! [ -x "$(command -v whiptail)" ]; then
   echo "Please install whiptail for use this script."
   exit 1
fi

OPTION=$(whiptail --title "Iptables-config-launcher" --menu "Welcome to iptables-config-launcher, what script do you want launch?" 15 60 4 \
   "1" "Configuration script (graphical version)" \
   "2" "Configuration script (console version)" \
   "3" " Backup script" 3>&1 1>&2 2>&3)

exitstatus=$?
if [ $exitstatus = 0 ]; then
   if [ "$OPTION" = "1" ]; then
      if [ -e ./iptables-config.sh ]; then
         sudo rm -rf ./iptables-config.sh
         sudo curl --tlsv1.3 -L -L https://iptables-config.me/assets/download/iptables-config_graphical_version.sh | sudo bash
      else
         sudo curl --tlsv1.3 -L -L https://iptables-config.me/assets/download/iptables-config_graphical_version.sh | sudo bash
      fi
   fi
   if [ "$OPTION" = "2" ]; then
      if [ -e ./iptables-config.sh ]; then
         sudo rm -rf ./iptables-config.sh
         sudo curl --tlsv1.3 -L -L https://iptables-config.me/assets/download/iptables-config_console_version.sh | sudo bash
      else
         sudo curl --tlsv1.3 -L -L https://iptables-config.me/assets/download/iptables-config_console_version.sh | sudo bash
      fi
   fi
   if [ "$OPTION" = "3" ]; then
      if [ -e ./iptables-config-backup.sh ]; then
         sudo rm -rf ./iptables-config-backup.sh
         sudo curl --tlsv1.3 -L https://iptables-config.me/assets/download/iptables-config-backup.sh | sudo bash
      else
         sudo curl --tlsv1.3 -L https://iptables-config.me/assets/download/iptables-config-backup.sh | sudo bash
      fi
   fi
fi
