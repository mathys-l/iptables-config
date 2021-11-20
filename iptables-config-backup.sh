#!/bin/bash

################################################################
# project: 'iptables-config'                                   #
# project-author: 'mathys-l; Erglug'                           #
# project-version: '0.1.0'                                     #
# license: 'GNU Affero General Public License v3.0'            #
# license-notice: 'https://iptables-config.me/LICENSE'         #
# github-link: 'https://github.com/mathys-l/Iptables-config'   #
################################################################
# check run in sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run script with sudo"
    exit 1
fi

#Switch distri
line=$(head -n 1 /etc/os-release)
case $line in
'NAME="Ubuntu"')
    echo 'Script optimised for Ubuntu'
    if [ -e /etc/cron.d/firewall ]; then
        sudo rm -rf /etc/cron.d/firewall
    fi
    if [ -e /etc/rc.local ]; then
        sudo rm -rf /etc/rc.local
    fi
    ;;

'NAME="Debian GNU/Linux"')
    echo 'Script optimised for Debian'
    if [ -e /etc/cron.d/firewall ]; then
        sudo rm -rf /etc/cron.d/firewall
    fi
    if [ -e /etc/rc.local ]; then
        sudo rm -rf /etc/rc.local
    fi
    ;;

'NAME="CentOS Linux"')
    echo 'Script optimised for CentOS'
    ;;

*)
    FILES=$(sed -n 2p /etc/os-release)
    if [[ "$FILES" = 'NAME="Debian GNU/Linux"' ]]; then
        echo 'Script optimised for Debian'
        if [ -e /etc/cron.d/firewall ]; then
            sudo rm -rf /etc/cron.d/firewall
        fi
        if [ -e /etc/rc.local ]; then
            sudo rm -rf /etc/rc.local
        fi
    else
        echo "Error, Optimised script for this distribution not found. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution."
        exit 1
    fi
    ;;

esac

# check for iptables
if ! [ -x "$(command -v iptables)" ]; then
    echo "Please install iptables for use this script."
    exit 1
fi

#check if firewall files exist
if [ -e /etc/init.d/firewall ]; then
    #if exist, check if folder /etc/backup-iptable-config/ exist
    if [ -d /etc/backup-iptable-config/ ]; then
        # if folder exist check if firewall file exist
        if [ -e /etc/backup-iptable-config/firewall ]; then
            line=$(head -n 1 /etc/os-release)
            case $line in
            'NAME="Ubuntu"')
                # remove actual configuration
                sudo rm -rf /etc/init.d/firewall
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo touch /etc/rc.local
                echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                sudo chmod +x /etc/rc.local
                sudo systemctl start rc-local
                echo 'Backup ended'
                ;;
            'NAME="Debian GNU/Linux"')
                # remove actual configuration
                sudo rm -rf /etc/init.d/firewall
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo touch /etc/rc.local
                echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                sudo chmod +x /etc/rc.local
                sudo systemctl start rc-local
                echo 'Backup ended'
                ;;
            'NAME="CentOS Linux"')
                # remove actual configuration
                sudo rm -rf /etc/init.d/firewall
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo chkconfig --add /etc/init.d/firewall
                echo 'Backup ended'
                ;;

            *)
                FILES=$(sed -n 2p /etc/os-release)
                if [[ "$FILES" = 'NAME="Debian GNU/Linux"' ]]; then
                    # remove actual configuration
                    sudo rm -rf /etc/init.d/firewall
                    #copy old configuration to configuration
                    sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                    sudo chmod +x /etc/init.d/firewall
                    touch /etc/rc.local
                    echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                    sudo chmod +x /etc/rc.local
                    sudo systemctl start rc-local
                    echo 'Backup ended'

                else
                    echo "Error, Cannot found good configuration for you Distribution. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution."
                    exit 1
                fi
                ;;

            esac

        else
            #error can't backup
            echo "No configuration found on backup folder"
            exit 1
        fi
    # else folder /etc/backup-iptable-config/ not exeist
    else
        #error can't backup
        echo "No backup folder found"
        exit 1
    fi
    # else no firewall file exist
else
    #if not exist, check if folder /etc/backup-iptable-config/ exist
    if [ -d /etc/backup-iptable-config/ ]; then
        # if folder exist check if firewall file exist
        if [ -e /etc/backup-iptable-config/firewall ]; then
            line=$(head -n 1 /etc/os-release)
            case $line in
            'NAME="Ubuntu"')
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo touch /etc/rc.local
                echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                sudo chmod +x /etc/rc.local
                sudo systemctl start rc-local
                ;;
            'NAME="Debian GNU/Linux"')
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo touch /etc/rc.local
                echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                sudo chmod +x /etc/rc.local
                sudo systemctl start rc-local
                ;;
            'NAME="CentOS Linux"')
                #copy old configuration to configuration
                sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                sudo chmod +x /etc/init.d/firewall
                sudo chkconfig --add /etc/init.d/firewall
                ;;

            *)
                FILES=$(sed -n 2p /etc/os-release)
                if [[ "$FILES" = 'NAME="Debian GNU/Linux"' ]]; then
                    #copy old configuration to configuration
                    sudo cp /etc/backup-iptable-config/firewall /etc/init.d/
                    sudo chmod +x /etc/init.d/firewall
                    sudo touch /etc/rc.local
                    echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
                    sudo chmod +x /etc/rc.local
                    sudo systemctl start rc-local
                else
                    echo "Error, Cannot found good configuration for you Distribution. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution."
                    exit 1
                fi
                ;;

            esac
        else
            #error can't backup
            echo "No configuration found on backup folder"
            exit 1
        fi
    # else folder /etc/backup-iptable-config/ not exeist
    else
        #error can't backup
        echo "No backup folder found"
        exit 1
    fi
fi
