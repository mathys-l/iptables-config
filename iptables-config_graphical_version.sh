#!/bin/bash

################################################################
# project: 'iptables-config'                                   #
# project-author: 'mathys-l; Erglug'                           #
# project-version: '0.1.0'                                     #
# license: 'GNU Affero General Public License v3.0'            #
# license-notice: 'https://iptables-config.me/LICENSE'         #
# github-link: 'https://github.com/mathys-l/Iptables-config'   #
################################################################

# check for sudo
if ! [ -x "$(command -v sudo)" ]; then
   echo "Please install sudo for use this script."
   exit 1
fi
clear

# check run in sudo
if [ "$EUID" -ne 0 ]; then
   echo "Please run script with sudo"
   exit 1
fi

# check for iptables
if ! [ -x "$(command -v iptables)" ]; then
   echo "Please install iptables for use this script."
   exit 1
fi

if ! [ -x "$(command -v whiptail)" ]; then
   echo "Please install whiptail for use this script."
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
      whiptail --msgbox "Error, Cannot found good configuration for you Distribution. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution." 10 100
      exit 1
   fi
   ;;

esac

#check if firewall files exist
if [ -e /etc/init.d/firewall ]; then
   #if file firewall exist set HASCONFIG on true
   hasconfig=true
   #if exist, check if folder /etc/backup-iptable-config/ exist
   if [ -d /etc/backup-iptable-config/ ]; then
      # if folder exist check if firewall file exist
      if [ -e /etc/backup-iptable-config/firewall ]; then
         # file exist delete file
         sudo rm -rf /etc/backup-iptable-config/firewall
         #move actual configuration firewall
         sudo mv /etc/init.d/firewall /etc/backup-iptable-config/firewall
      else
         #just move actual configuration
         sudo mv /etc/init.d/firewall /etc/backup-iptable-config/firewall
      fi
   # else folder /etc/backup-iptable-config/ not exeist
   else
      #create folder
      sudo mkdir /etc/backup-iptable-config/
      #move actual configuration
      sudo mv /etc/init.d/firewall /etc/backup-iptable-config/firewallfi
   fi
   # else no firewall file exist
else
   #if file firewall exist set HASCONFIG on false
   hasconfig=false
   #if not exist, check if folder /etc/backup-iptable-config/ exist
   if [ -d /etc/backup-iptable-config/ ]; then
      # if folder exist check if firewall file exist
      if [ -e /etc/backup-iptable-config/firewall ]; then
         # file exist delete file
         sudo rm -rf /etc/backup-iptable-config/firewall
         #create void file because no actual configuration
         sudo touch /etc/backup-iptable-config/firewall
      else
         #just create void file because no actual configuration
         sudo touch /etc/backup-iptable-config/firewall
      fi
   # else folder /etc/backup-iptable-config/ not exeist
   else
      #create folder
      sudo mkdir /etc/backup-iptable-config/
      #create void file because no actual configuration
      sudo touch /etc/backup-iptable-config/firewall
   fi
fi

if [ -e ./firewall ]; then
   sudo truncate -s 0 ./firewall
else
   sudo touch ./firewall
fi

sudo echo '#!/bin/bash

### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     false
# Short-Description: firewall with iptables
### END INIT INFO


# File genered with iptables-config script. Can found on https://github.com/mathys-l/Iptables-config
echo Setting firewall rules...

# Empty actual rules
iptables -t filter -F
iptables -t filter -X
echo " - Empty rules: [OK]"' >>./firewall

if (whiptail --title "Allow port 22" --yesno "Do you want allow the basic ssh port on the incoming connection?" 10 60); then
   sudo echo '
# Allow base ssh port
iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
echo " - Allow SSH on port 22: [OK]"

# Keep established connections
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
echo " - Keep established connections: [OK]"

# Forbidden any incoming connection
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
echo " - Forbidden any incoming connection: [OK]"

# Forbidden any outgoing connection
iptables -t filter -P OUTPUT DROP
echo " - Forbidden any outgoing connection: [OK]"' >>./firewall
else
   sudo echo '
# Keep established connections
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
echo " - Keep established connections: [OK]"

# Forbidden any incoming connection
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
echo " - Forbidden any incoming connection: [OK]"

# Forbidden any outgoing connection
iptables -t filter -P OUTPUT DROP
echo " - Forbidden any outgoing connection: [OK]"' >>./firewall
fi

if (whiptail --title "Allow port 20, 21, 80, 53, 123" --yesno "Do you want allow DNS, FTP, HTTP, NTP requests on the outgoing connection?" 10 60); then
   sudo echo '
#Allow DNS, FTP, HTTP, NTP
iptables -t filter -A OUTPUT -p tcp --dport 20 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 21 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT
echo " - Allow DNS, FTP, HTTP, NTP request: [OK]"' >>./firewall
fi

if (whiptail --title "Allow port loopback" --yesno "Do you want allow loopback requests on the incoming and outgoing connection?" 10 60); then
   sudo echo '
#Allow loopback
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT
echo " - Allow loopback : [OK]"' >>./firewall
fi

if (whiptail --title "Using port icmp" --yesno "Do you want allow ping requests on the incoming and outgoing connection?" 10 60); then
   sudo echo '
#Allow loopback
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT
echo " - Allow loopback : [OK]"' >>./firewall
fi

if (whiptail --title "Using port 80, 443" --yesno "Do you want allow HTTP, HTTPS requests for an apache/ nginx server on the incoming connection?" 10 60); then
   sudo echo '
# Allow HTTP, HTTPS
iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
echo " - Apache/ Nginx server allow: [OK]"' >>./firewall
fi

if (whiptail --title "Using port 20, 21" --yesno "Do you want allow FTP requests on the incoming connection?" 10 60); then
   sudo echo '
# Allow FTP
modprobe ip_conntrack
modprobe ip_conntrack_ftp
iptables -t filter -A INPUT -p tcp --dport 20 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
echo " - Allow FTP server: [OK]"' >>./firewall
fi

if (whiptail --title "Using port 25, 110, 143" --yesno "Do you want allow Mail requests on the incoming and outgoing connection?" 10 60); then
   sudo echo '
# Allow Mail port
iptables -t filter -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 110 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 143 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 25 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 110 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 143 -j ACCEPT
echo " - Mail server allow: [OK]"' >>./firewall
fi

if (whiptail --title "Limit Syn-Flood" --yesno "Do you want limit Syn-Flood to 1 secondes?" 10 60); then
   sudo echo '
# Limit Syn-Flood
iptables -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT
iptables -A FORWARD -p udp -m limit --limit 1/second -j ACCEPT
echo " - Syn-Flood limitation: [OK]"' >>./firewall
fi

if (whiptail --title "Block Spoofing" --yesno "Do you want block Spoofing?" 10 60); then
   sudo echo '
# Allow block Spoofing
iptables -N SPOOFED
iptables -A SPOOFED -s 127.0.0.0/8 -j DROP
iptables -A SPOOFED -s 169.254.0.0/12 -j DROP
iptables -A SPOOFED -s 172.16.0.0/12 -j DROP
iptables -A SPOOFED -s 192.168.0.0/16 -j DROP
iptables -A SPOOFED -s 10.0.0.0/8 -j DROP
echo " - Spoofing block: [OK]"

#IP blacklist' >>./firewall
else
   sudo echo '
#IP blacklist' >>./firewall
fi

while [ "$Ip" != "end" ]; do
   Ip=$(whiptail --title "Ip block" --inputbox "Would you want blacklist an ip? (if you don't want add click on 'cancel')" 10 60 3>&1 1>&2 2>&3)
   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
      re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'
      if [[ "$Ip" =~ $re ]]; then
         sudo echo "
iptables -A INPUT -s $REP9 -j DROP" >>./firewall
         whiptail --msgbox "Ip $Ip succefully added." 10 100
      else
         whiptail --msgbox "IP incorect, please type correct ip." 10 100
      fi
   else
      Ip="end"
   fi
done

sudo echo '
echo " - Ip blacklist: [OK]"
#Custom port incoming' >>./firewall

while [ "$PortIn" != "end" ]; do
   PortIn=$(whiptail --title "Incoming port add" --inputbox "Would you want add another port on incoming connection? (if you don't want add click on 'cancel')" 10 60 3>&1 1>&2 2>&3)

   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      if [[ "$PortIn" =~ [1-9] ]]; then
         if [[ "$PortIn" -lt 65536 ]]; then
            sudo echo "
iptables -t filter -A INPUT -p tcp --dport $PortIn -j ACCEPT
iptables -t filter -A INPUT -p udp --dport $PortIn -j ACCEPT" >>./firewall
            whiptail --msgbox "Port $PortIn succefully added." 10 100
         else
            whiptail --msgbox "Port incorect, please type correct port." 10 100
         fi
      else
         whiptail --msgbox "Port incorect, please type correct port." 10 100
      fi
   else
      PortIn="end"
   fi
done

sudo echo '
echo " - Custom port incoming: [OK]"
#Custom port outgoing' >>./firewall

while [ "$PortOu" != "end" ]; do
   PortOu=$(whiptail --title "Outgoing port add" --inputbox "Would you want add another port on outgoing connection? (if you don't want add click on 'cancel')" 10 60 3>&1 1>&2 2>&3)

   exitstatus=$?
   if [ $exitstatus = 0 ]; then
      if [[ "$PortOu" =~ [1-9] ]]; then
         if [[ "$PortOu" -lt 65536 ]]; then
            sudo echo "
iptables -t filter -A OUTPUT -p tcp --dport $PortOu -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport $PortOu -j ACCEPT" >>./firewall
            whiptail --msgbox "Port $PortOu succefully added." 10 100
         else
            whiptail --msgbox "Port incorect, please type correct port." 10 100
         fi
      else
         whiptail --msgbox "Port incorect, please type correct port." 10 100
      fi
   else
      PortOu="end"
   fi
done

sudo echo '
echo " - Custom port outgoing: [OK]"

# End configuration
echo " - Firewall config: [OK]"' >>./firewall

if (whiptail --title "Save configuration" --yesno "Do you want save you'r configuration?" 10 60); then

   line=$(head -n 1 /etc/os-release)
   case $line in
   'NAME="Ubuntu"')
      sudo chmod +x ./firewall
      sudo cp ./firewall /etc/init.d/
      sudo touch /etc/rc.local
      echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
      sudo chmod +x /etc/rc.local
      sudo systemctl start rc-local
      sudo rm -rf ./firewall
      ;;
   'NAME="Debian GNU/Linux"')
      sudo chmod +x ./firewall
      sudo cp ./firewall /etc/init.d/
      sudo touch /etc/rc.local
      echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
      sudo chmod +x /etc/rc.local
      sudo systemctl start rc-local
      sudo rm -rf ./firewall
      ;;

   'NAME="CentOS Linux"')
      sudo chmod +x ./firewall
      sudo cp ./firewall /etc/init.d/
      sudo chkconfig --add /etc/init.d/firewall
      sudo rm -rf ./firewall
      ;;

   *)
      FILES=$(sed -n 2p /etc/os-release)
      if [[ "$FILES" = 'NAME="Debian GNU/Linux"' ]]; then
         sudo chmod +x ./firewall
         sudo cp ./firewall /etc/init.d/
         sudo touch /etc/rc.local
         echo '#!/bin/sh
/etc/init.d/firewall &' >>/etc/rc.local
         sudo chmod +x /etc/rc.local
         sudo systemctl start rc-local
         sudo rm -rf ./firewall
      else
         whiptail --msgbox "Error, Cannot found good configuration for you Distribution. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution." 10 100
         exit 1
      fi
      ;;

   esac
   whiptail --msgbox "Configuration finish and save." 10 100
else
   if [ "$hasconfig" == "true" ]; then
      #if old configuration exist setup old configuration
      sudo rm -rf /etc/init.d/firewall
      sudo mv /etc/backup-iptable-config/firewall /etc/init.d/firewall
      whiptail --msgbox "Configuration cancel. Old configuration have been setup." 10 100
   else
      #if remove void file
      sudo rm -rf /etc/init.d/firewall
      sudo rm -rf /etc/backup-iptable-config/
      whiptail --msgbox "Configuration cancel." 10 100
   fi
fi

if (whiptail --title "Reboot" --yesno "Do you want reboot this machine?" 10 60); then
   sudo reboot
fi
