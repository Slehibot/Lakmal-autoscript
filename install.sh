#!/bin/sh
# SSH Tunnel Auto Script
# Version : 2.2.0

echo "After this operation, Stunnel, Dropbear, Squid and Badvpn will be installed on your server."
read -p "Do you want to continue? [y/n]" CONT
if [[ ! $CONT =~ ^[Yy]$ ]]; then
  echo "Abort.";
  exit 100
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[95mYou must be root to do this.\e[0m" 1>&2
   exit 100
fi

apt-get update
apt-get upgrade -y

echo -e "\e[96mInstalling dependancies\e[0m"
apt-get install -y libnss3* libnspr4-dev gyp ninja-build git cmake libz-dev build-essential 
apt-get install -y pkg-config cmake-data net-tools libssl-dev dnsutils speedtest-cli psmisc
apt-get install -y dropbear stunnel4 fish

pubip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
if [ "$pubip" == "" ];then
    pubip=`ifconfig eth0 | awk 'NR==2 {print $2}'`
fi
if [ "$pubip" == "" ];then
    pubip=`ifconfig ens3 | awk 'NR==2 {print $2}'`
fi
if [ "$pubip" == "" ];then
    echo -e "\e[95mIncompatible Server!.\e[0m" 1>&2
    exit 100
fi

echo -e "\e[96mChecking dropbear is installed\e[0m"
FILE=/etc/default/dropbear
if [ -f "$FILE" ]; then
    cp "$FILE" /etc/default/dropbear.bak
    rm "$FILE"
fi

echo -e "\e[96mCreating dropbear config\e[0m"
cat >> "$FILE" <<EOL
# disabled because OpenSSH is installed
# change to NO_START=0 to enable Dropbear
NO_START=0
# the TCP port that Dropbear listens on
DROPBEAR_PORT=444

# any additional arguments for Dropbear
DROPBEAR_EXTRA_ARGS="-p 80 -w -g"

# specify an optional banner file containing a message to be
# sent to clients before they connect, such as "/etc/issue.net"
DROPBEAR_BANNER="/etc/issue.net"

# RSA hostkey file (default: /etc/dropbear/dropbear_rsa_host_key)
#DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"

# DSS hostkey file (default: /etc/dropbear/dropbear_dss_host_key)
#DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"

# ECDSA hostkey file (default: /etc/dropbear/dropbear_ecdsa_host_key)
#DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"

# Receive window size - this is a tradeoff between memory and
# network performance
DROPBEAR_RECEIVE_WINDOW=65536
EOL

echo -e "\e[96mBackup old dropbear banner\e[0m"
FILE2=/etc/issue.net
if [ -f "$FILE2" ]; then
    cp "$FILE2" /etc/issue.net.bak
    rm "$FILE2"
fi

echo -e "\e[96mCreating dropbear banner\e[0m"
cat >> "$FILE2" <<EOL
<h4>&#9734; <font color="#FF6347">Premium Server</font> &#9734;</h4><b><font color="#2E86C1">===============================</font></b><br><b><span style="color:#BA55D3">╔═══════*.·:·.✧ ✦ ✧.·:·.*═══════╗</span></b><br> <b><h2><span style="color:#1f15e9;">&nbsp;&nbsp;꧁ &#127473&#127472 SL EHI BOT &#127473&#127472 ꧂</b></h2></span><b><span style="color:#BA55D3">╚═══════*.·:·.✧ ✦ ✧.·:·.*═══════╝</span></b><br><br><b><span style="color:#8A2BE2">&#187; NO SPAM !!! &#171;</span><br><span style="color:#A52A2A">&#187; NO DDOS !!! &#171;</span><br><span style="color:#6495ED">&#187; NO HACKING !!! &#171;</span><br><span style="color:#008B8B">&#187; NO CARDING !!! &#171;</span><br><span style="color:#9932CC">&#187; NO TORRENT !!! &#171;</span><br><span style="color:#1E90FF">&#187; NO OVER DOWNLOADING !!! &#171;</span></b><br><br><b><font color="#2E86C1">===============================</font></b><br><b><font color="#D35400">&#127473&#127472 &#187; SL EHI BOT&trade; &#171; &#127473&#127472</font> Auto Script</b><br><br><b>Create By: <font color="#138D75">Lakmal Sandaru</font><font color="#A52A2A">&nbsp;&nbsp;&#187; InfinityJE&trade;&#171;</font></b><br><b>Join Channel:<font color="#2E86C1">https://t.me/slehiteam  </font></b><br><br><b><font color="#2E86C1">===============================</font></b>
<br>
EOL

echo -e "\e[96mStarting dropdear services\e[0m"
/etc/init.d/dropbear start

echo -e "\e[96mChecking stunnel is installed\e[0m"
FILE3=/etc/stunnel/stunnel.conf
if [ -f "$FILE3" ]; then
	cp "$FILE3" /etc/stunnel/stunnel.conf.bak
	rm "$FILE3"
fi

echo -e "\e[96mCreating stunnel config\e[0m"
cat >> "$FILE3" <<EOL
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
connect = 444
accept = 443
EOL

echo -e "\e[96mCreating keys\e[0m"
KEYFILE=/etc/stunnel/stunnel.pem
if [ ! -f "$KEYFILE" ]; then
	openssl genrsa -out key.pem 2048
	openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=AU/ST=./L=./O=./OU=./CN=./emailAddress=."
	cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
fi

echo -e "\e[96mEnabling stunnel services\e[0m"
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

echo -e "\e[96mStarting stunnel services\e[0m"
/etc/init.d/stunnel4 start

echo -e "\e[96mCompile and installing badvpn\e[0m"
if [ ! -d "/root/badvpn/" ] 
then
    sudo dpkg --configure -a
	git clone https://github.com/ambrop72/badvpn.git /root/badvpn
	cd /root/badvpn/
	cmake /root/badvpn/ -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_SERVER=1 -DBUILD_CLIENT=1 -DBUILD_UDPGW=1 -DBUILD_TUN2SOCKS=1 && make
	make install
fi

echo -e "\e[96mChecking rc.local is exist\e[0m"
FILE4=/etc/rc.local
if [ -f "$FILE4" ]; then
    cp "$FILE4" /etc/rc.local.bak
    rm "$FILE4"
fi

echo -e "\e[96mCreating rc.local\e[0m"
cat >> "$FILE4" <<EOL
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 999 --client-socket-sndbuf 1048576
exit 0
EOL

echo -e "\e[96mSetting up permissions for rc.local\e[0m"
chmod +x /etc/rc.local

echo -e "\e[96mInstalling squid\e[0m"
apt-get install -y squid

echo -e "\e[96mChecking squid is installed\e[0m"
FILE5=/etc/squid/squid.conf
if [ -f "$FILE5" ]; then
    cp "$FILE5" /etc/squid/squid.conf.bak
    rm "$FILE5"
fi

echo -e "\e[96mConfiguring squid\e[0m"
cat >> "$FILE5" <<EOL
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst ${pubip}
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8080
http_port 3128
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
EOL

echo -e "\e[96mEnabling ssh password authentication\e[0m"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

echo -e "\e[96mSetting up banner for ssh\e[0m"
sed -i 's/#Banner none/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config

echo -e "\e[96mRestarting services. Please wait...\e[0m"
/etc/init.d/dropbear restart
/etc/init.d/stunnel4 restart
service squid restart
service ssh restart


[Install]
WantedBy=multi-user.target
EOF
}
fun_panel()
{
mkdir /etc/slehibot-vps-auto-script
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ChangeUser.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ChangePorts.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/UserManager.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/Banner.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/DelUser.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/ListUsers.sh
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/etc/RemoveScript.sh
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
wget https://raw.githubusercontent.com/Slehibot/slehibot-vps-auto-script/main/menu
mv ChangeUser.sh /etc/slehibot-vps-auto-script/ChangeUser.sh
mv ChangePorts.sh /etc/slehibot-vps-auto-script/ChangePorts.sh
mv UserManager.sh /etc/slehibot-vps-auto-script/UserManager.sh
mv Banner.sh /etc/slehibot-vps-auto-script/Banner.sh
mv DelUser.sh /etc/slehibot-vps-auto-script/DelUser.sh
mv ListUsers.sh /etc/slehibot-vps-auto-script/ListUsers.sh
mv RemoveScript.sh /etc/slehibot-vps-auto-script/RemoveScript.sh
mv speedtest-cli /etc/slehibot-vps-auto-script/speedtest-cli
mv menu /usr/local/bin/menu
chmod +x /etc/slehibot-vps-auto-script/ChangeUser.sh
chmod +x /etc/slehibot-vps-auto-script/ChangePorts.sh
chmod +x /etc/slehibot-vps-auto-script/UserManager.sh
chmod +x /etc/slehibot-vps-auto-script/Banner.sh
chmod +x /etc/slehibot-vps-auto-script/DelUser.sh
chmod +x /etc/slehibot-vps-auto-script/ListUsers.sh
chmod +x /etc/slehibot-vps-auto-script/RemoveScript.sh
chmod +x /etc/slehibot-vps-auto-script/speedtest-cli
chmod +x /usr/local/bin/menu
}
fun_service_start()
{
#enabling and starting all services

useradd -m udpgw


#configure user shell to /bin/false
chsh -s `which fish`
echo /bin/false >> /etc/shells
clear

ln -s /etc/issue.net $HOME/banner.txt
echo " "
echo -e "\e[96mInstallation has been completed!!\e[0m"
echo " "
echo "--------------------------- Configuration Setup Server -------------------------"
echo " "
echo "Server Information"
echo "   - IP address 	: ${pubip}"
echo "   - SSH 		: 22"
echo "   - Dropbear 		: 80"
echo "   - Stunnel 		: 443"
echo "   - Badvpn 		: 7300"
echo "   - Squid 		: 8080/3128"
echo " "
echo -e "\e[95mCreate users and reboot your vps before use.\e[0m"
echo " "

#add users

echo -ne "${YELLOW}Enter the username : "; read username
while true; do
    read -p "Do you want to genarate a random password ? (Y/N) " yn
    case $yn in
        [Yy]* ) password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-9};echo;); break;;
        [Nn]* ) echo -ne "Enter password (please use a strong password) : "; read password; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -ne "Enter No. of Days till expiration : ";read nod
exd=$(date +%F  -d "$nod days")
useradd -e $exd -M -N -s /bin/false $username && echo "$username:$password" | chpasswd &&
clear &&
echo -e "${GREEN}User Detail" &&
echo -e "${RED}-----------" &&
echo -e "${GREEN}\nUsername :${YELLOW} $username" &&
echo -e "${GREEN}\nPassword :${YELLOW} $password" &&
echo -e "${GREEN}\nExpire Date :${YELLOW} $exd ${ENDCOLOR}" ||
echo -e "${RED}\nFailed to add user $username please try again.${ENDCOLOR}"
echo -e "\e[95mCreate users and reboot your vps before use.\e[0m"
echo " "
