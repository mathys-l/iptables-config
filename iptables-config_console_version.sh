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

# check for iptables
if ! [ -x "$(command -v iptables)" ]; then
   echo "Please install iptables for use this script."
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
   START="0"
while [ "$START" = 0 ]; do
   START=$"1"
done
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

read -p "Do you want allow the basic ssh port on the incoming connection {Using port 22}? (y/n): " REP
while [ "$REP" != "n" ] || [ "$REP" = "y" ] || [ "$REP" = "yes" ] || [ "$REP" = "Y" ] || [ "$REP" = "Yes" ]; do
   if [ "$REP" = "y" ] || [ "$REP" = "yes" ] || [ "$REP" = "Y" ] || [ "$REP" = "Yes" ]; then
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
done

read -p "Do you want allow DNS, FTP, HTTP, NTP requests on the outgoing connection {Using port 20, 21, 80, 53, 123}? (y/n): " REP1

if [ "$REP1" = "y" ] || [ "$REP1" = "yes" ] || [ "$REP1" = "Y" ] || [ "$REP1" = "Yes" ]; then
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

read -p "Do you want allow loopback requests on the incoming and outgoing connection {Using port lo}? (y/n): " REP2

if [ "$REP2" = "y" ] || [ "$REP2" = "yes" ] || [ "$REP2" = "Y" ] || [ "$REP2" = "Yes" ]; then
   sudo echo '
#Allow loopback 
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT
echo " - Allow loopback : [OK]"' >>./firewall
fi

read -p "Do you want allow ping requests on the incoming and outgoing connection {Using port icmp}? (y/n): " REP3

if [ "$REP3" = "y" ] || [ "$REP3" = "yes" ] || [ "$REP3" = "Y" ] || [ "$REP3" = "Yes" ]; then
   sudo echo '
#Allow loopback 
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT
echo " - Allow loopback : [OK]"' >>./firewall
fi

read -p "Do you want allow HTTP, HTTPS requests for an apache/ nginx server on the incoming connection {Using port 80, 443} (y/n): " REP4

if [ "$REP4" = "y" ] || [ "$REP4" = "yes" ] || [ "$REP4" = "Y" ] || [ "$REP4" = "Yes" ]; then
   sudo echo '
# Allow HTTP, HTTPS
iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
echo " - Apache/ Nginx server allow: [OK]"' >>./firewall
fi

read -p "Do you want allow FTP requests on the incoming connection {Using port 20, 21}? (y/n): " REP5

if [ "$REP5" = "y" ] || [ "$REP" = "yes" ] || [ "$REP" = "Y" ] || [ "$REP" = "Yes" ]; then
   sudo echo '
# Allow FTP
modprobe ip_conntrack
modprobe ip_conntrack_ftp
iptables -t filter -A INPUT -p tcp --dport 20 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 21 -j ACCEPT
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
echo " - Allow FTP server: [OK]"' >>./firewall
fi

read -p "Do you want allow Mail requests on the incoming and outgoing connection {Using port 25, 110, 143}? (y/n): " REP6

if [ "$REP6" = "y" ] || [ "$REP6" = "yes" ] || [ "$REP6" = "Y" ] || [ "$REP6" = "Yes" ]; then
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

read -p "Do you want limit Syn-Flood to 1 secondes? (y/n): " REP7

if [ "$REP7" = "y" ] || [ "$REP7" = "yes" ] || [ "$REP7" = "Y" ] || [ "$REP7" = "Yes" ]; then
   sudo echo '
# Limit Syn-Flood 
iptables -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT
iptables -A FORWARD -p udp -m limit --limit 1/second -j ACCEPT
echo " - Syn-Flood limitation: [OK]"' >>./firewall
fi

read -p "Do you want block Spoofing? (y/n): " REP8

if [ "$REP8" = "y" ] || [ "$REP8" = "yes" ] || [ "$REP8" = "Y" ] || [ "$REP8" = "Yes" ]; then
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

while [ "$REP9" != "n" ]; do
   read -p "Would you want blacklist an ip (if you don't want add type 'n'): " REP9
   re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
   re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'

   if [[ "$REP9" =~ $re ]]; then
      sudo echo "
iptables -A INPUT -s $REP9 -j DROP" >>./firewall
   elif [ "$REP9" != "n" ]; then
      echo "Please type correct ip."
   fi
done

sudo echo '
echo " - Ip blacklist: [OK]"
#Custom port incoming' >>./firewall

while [ "$REP10" != "n" ]; do

   read -p "Would you want add another port on incoming connection (if you don't want add type 'n): " REP10
   if [[ "$REP10" =~ [1-9] ]]; then
      if [[ "$REP10" -lt 65536 ]]; then
         sudo echo "
iptables -t filter -A INPUT -p tcp --dport $REP10 -j ACCEPT
iptables -t filter -A INPUT -p udp --dport $REP10 -j ACCEPT" >>./firewall
      else
         echo "Please type an correct port."
      fi
   elif [ "$REP10" != "n" ]; then
      echo "Please type an correct port."
   fi
done

sudo echo '
echo " - Custom port incoming: [OK]"
#Custom port outgoing' >>./firewall

while [ "$REP11" != "n" ]; do

   read -p "Would you want add another port on outgoing connection (if you don't want add type 'n): " REP11
   if [[ "$REP11" =~ [1-9] ]]; then
      if [[ "$REP11" -lt 65536 ]]; then
         sudo echo "
iptables -t filter -A OUTPUT -p tcp --dport $REP11 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport $REP11 -j ACCEPT" >>./firewall
      else
         echo "Please type an correct port."
      fi
   elif [ "$REP11" != "n" ]; then
      echo "Please type an correct port."
   fi
done

sudo echo '
echo " - Custom port outgoing: [OK]"

# End configuration
echo " - Firewall config: [OK]"' >>./firewall

read -p "Do you want save this configuration? (y/n): " REP13
if [ "$REP13" == "y" ] || [ "$REP13" == "yes" ] || [ "$REP13" == "Y" ] || [ "$REP13" == "Yes" ]; then
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
         echo "Error, Cannot found good configuration for you Distribution. Please open issue on https://github.com/mathys-l/Iptables-config and say you'r distribution."
         exit 1
      fi
      ;;

   esac

   echo "Configuration finish"
fi
else

if [ "$hasconfig" == "true" ]; then
   #if old configuration exist setup old configuration
   sudo rm -rf /etc/init.d/firewall
   sudo mv /etc/backup-iptable-config/firewall /etc/init.d/firewall
   echo "Configuration cancel. Old configuration have been setup."
else
   #if remove void file
   sudo rm -rf /etc/init.d/firewall
   sudo rm -rf /etc/backup-iptable-config/
   echo "Configuration cancel."
fi

read -p "Do you want reboot this machine? (y/n): " REP14
if [ "$REP14" = "y" ] || [ "$REP14" = "yes" ] || [ "$REP14" = "Y" ] || [ "$REP14" = "Yes" ]; then
   sudo reboot
fi
