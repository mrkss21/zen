#!/bin/bash

# Version history:
# 0.1a 25.07.2018 - first release.
# 0.2a 27.07.2018 - sycn naming with doc. Addins legal warning
# 0.3a 27.07.2018 - adding "make swap" by people requests.

function ExitErrorMessage(){
	[ -n "$1" ] && echo >&2 "$1"
	exit 1
}

function WelcomeScreen(){
	echo "Welcome to ZenCash node lazy-install script by 640kilobyte."
	echo "Version 0.3a 27.07.2018"
	echo ""
	echo "This script will prepare system for Secure/Super node:"
	echo "0) Add 4G /swapfile if total memory+swap less then ~4G"
	echo "1) Install software"
	echo "2) Getting certificate"
	echo "3) Configure zend"
	echo "4) Install tracker app"
	echo "5) Make simple server security"
	echo ""
	echo "Based on manual https://sites.google.com/view/zencashnodedebian/"
	echo "If you can help in the development of this manual or need help with a non-standard error, please contact @640kilobyte on official ZenCash Discord  channel or ZenCash channel at Telegram messenger."
	echo "I hope you liked this script. With the installation of the node you helped to ZenCash community - have become an important part of a large distributed network."
	echo "If you want to additionally donate to this script creator - ZenCash address znVjLJ1FFtCu7ZEUJFuksEGLugkzVCGRpb1"
	echo ""
	echo "Legal warning:"
	echo "This script agree TOS of LetsEncrypt located on https://letsencrypt.org/repository/"
	echo "If you not agree with this - press ctrl-c immediatly."
}

function ScreenSpacer(){
	echo
	echo
	echo
}

function FinalScreen(){
	echo "Now you need manual operation:"
	echo "1) Wait while zend finish syncing blocks. Look progress:"
	echo "     zen-cli getinfo"
	echo "2) Check for exist z_address on node:"
	echo "     zen-cli z_listaddresses"
	echo "...if not exist - create:"
	echo "     zen-cli z_getnewaddress"
	echo "3) Send to z_address 5 transactions (by 0.1 zen for example)"
	echo "3) Check balance:"
	echo "     zen-cli z_gettotalbalance"
	echo "4) Setup tracker:"
	echo "    cd ~/nodetracker/ && node setup"
	echo "5) Run tracker:"
	echo "    sudo systemctl start zentracker@$USER"
}

function AddSwap(){
	PhyMemTotal=$( free -m | grep -F "Mem:" | awk '{print $2}' )
	SwapTotal=$( free -m | grep -F "Swap:" | awk '{print $2}' )
	if [[ $(( $PhyMemTotal + $SwapTotal )) -le 4000 ]]; then
		sudo fallocate -l 4G /swapfile
		sudo chmod 0600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		sudo cp /etc/fstab /etc/fstab.old
		sudo cat /etc/fstab.old | grep -vF '/swapfile none swap defaults 0 0' | sudo tee /etc/fstab
		echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
	fi
}

function SetHostname(){
	echo $FQDN | cut -d"." -f1 | sudo tee /etc/hostname
	sudo cp /etc/hosts /etc/hosts.old
	echo "127.0.1.1 $FQDN $( echo $FQDN | cut -d"." -f1 )" | sudo tee /etc/hosts
	cat /etc/hosts.old | sudo tee -a /etc/hosts
	sudo hostname `cat /etc/hostname`
	[[ `hostname -f` == "$FQDN" ]]
}

function DetectOS(){
	DISTRO=$( lsb_release -is 2>/dev/null )
	if [[ $DISTRO == "Debian" ]] || [[ $DISTRO == "Ubuntu" ]]; then
		export DISTRO
	else
		ExitErrorMessage "Can't detect OS. Supported only Debian/Ubuntu modern family."
	fi
}

function SoftwareInstall(){
	sudo apt-get -y update
	# zend repo
	sudo apt-get -y install dirmngr apt-transport-https
	echo "deb https://zencashofficial.github.io/repo/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/zen.list
	gpg --keyserver ha.pool.sks-keyservers.net --recv 219F55740BBF7A1CE368BA45FB7053CE4991B669
	gpg --export 219F55740BBF7A1CE368BA45FB7053CE4991B669 | sudo apt-key add -
	# certbot repo and install
	if [[ $DISTRO == "Debian" ]]; then
		echo "deb http://ftp.debian.org/debian $(lsb_release -cs)-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
		sudo apt-get -y install -t $(lsb_release -cs)-backports certbot 
	else
		sudo apt-get -y install software-properties-common
		sudo add-apt-repository -y ppa:certbot/certbot
		sudo apt-get -y install certbot
	fi
	# Node.JS repo
	if [[ $DISTRO == "Debian" ]]; then
		curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	fi
	sudo apt-get -y install ntp ssl-cert curl git pwgen zen npm nodejs ufw fail2ban rkhunter exim4 mailutils
}

function GetCert(){
	# getting certificate 
	sudo certbot certonly -n --agree-tos --register-unsafely-without-email --standalone -d $( hostname -f )
	# install zend cert
	mkdir -p $HOME/.zen/cert/
	sudo cp /etc/letsencrypt/live/$( hostname -f )/fullchain.pem $HOME/.zen/cert/$( hostname -f ).cert
	sudo cp /etc/letsencrypt/live/$( hostname -f )/privkey.pem $HOME/.zen/cert/$( hostname -f ).key
	sudo chown -R $USER:$USER $HOME/.zen/cert/
	sudo chmod -R 700 $HOME/.zen/cert/
	# install CA cert
	sudo cp /etc/letsencrypt/live/$( hostname -f )/chain.pem /usr/local/share/ca-certificates/letsencrypt-ca.crt
	sudo update-ca-certificates
	# make update hook
	sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
cat <<\EOF | sudo tee /etc/letsencrypt/renewal-hooks/deploy/zend-$USER-`hostname -f`.sh && sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/zend-$USER-$( hostname -f ).sh
#!/bin/bash
# this script install certificated to zend folder for user folders.
# zend-USER-HOSTNAME.sh
self=$0
user=`basename $self .sh | cut -d- -f2`
host=`basename $self .sh | cut -d- -f3-`
for domain in $RENEWED_DOMAINS; do
  if [ "$domain" == "$host" ]; then
  certfolder="/home/$user/.zen/cert/"
  # make certificate folder
  mkdir -p $certfolder
  # copy certificate
  cp "$RENEWED_LINEAGE/fullchain.pem" "$certfolder/$domain.cert"
  cp "$RENEWED_LINEAGE/privkey.pem" "$certfolder/$domain.key"
  # permissions
  chown -R $user:$user "$certfolder"
  chmod -R 700 $certfolder
  # restart zend service
  systemctl restart zend@$user
  # sendig mail
  echo "Zend certificates for user $user and domain $host was installed." | mail -s "`hostname -f`: certificate update" root
 fi
done
EOF
}

function FetchzkSNARK(){
	zen-fetch-params
}

function SetupZend(){
	ipv4=$( ip route get 8.8.8.8 | grep -oP '(?<=src )[^ ]+' )
	ipv6=$( ip -6 route get 2001:4860:4860::8888 | grep -oP '(?<=src )[^ ]+')
	externalip=$( [ -n "$ipv4" ] && echo "externalip=$ipv4"; [ -n "$ipv6" ] && echo "externalip=$ipv6" )
	cat <<EOF | tee $HOME/.zen/zen.conf
rpcuser=$(pwgen -s 16 1)
rpcpassword=$(pwgen -s 64 1)
rpcport=18231
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
txindex=1
logtimestamps=1
port=9033
$externalip
tlscertpath=$HOME/.zen/cert/$(hostname -f).cert
tlskeypath=$HOME/.zen/cert/$(hostname -f).key
EOF
	cat <<EOF | sudo tee /etc/systemd/system/zend@.service
[Unit]
Description=ZenCash daemon

[Service]
User=%i
Type=forking
ExecStart=/usr/bin/zend -daemon -pid=/home/%i/.zen/zend.pid
PIDFile=/home/%i/.zen/zend.pid
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

	sudo systemctl enable zend@$USER
	sudo systemctl start zend@$USER
}

function SetupTracker(){
	cd ~/ && git clone https://github.com/ZencashOfficial/nodetracker.git
	cd nodetracker && npm install
cat <<EOF | sudo tee /etc/systemd/system/zentracker@.service
[Unit]
Description=ZenCash node daemon installed on ~/nodetracker/ 

[Service]
User=%i
Type=simple
WorkingDirectory=/home/%i/nodetracker/
ExecStart=/usr/local/bin/node /home/%i/nodetracker/app.js
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

sudo systemctl enable zentracker@$USER
}

function SimpleSecurity(){
	sudo systemctl enable fail2ban
	sudo systemctl start fail2ban
	sudo ufw default allow outgoing
	sudo ufw default deny incoming
	sudo ufw allow ssh/tcp
	sudo ufw limit ssh/tcp
	sudo ufw allow http/tcp
	sudo ufw allow https/tcp
	sudo ufw allow 9033/tcp
	sudo ufw allow 19033/tcp
	sudo ufw logging on
	sudo ufw -f enable
	sudo mv /etc/rkhunter.conf /etc/rkhunter.conf.old
	sudo mv /etc/default/rkhunter /etc/default/rkhunter.old
	cat <<\EOF | sudo tee /etc/rkhunter.conf
UPDATE_MIRRORS=0
MAIL-ON-WARNING=root
MAIL_CMD=mail -s "[rkhunter] Warnings found for ${HOST_NAME}"
TMPDIR=/var/lib/rkhunter/tmp
DBDIR=/var/lib/rkhunter/db
SCRIPTDIR=/usr/share/rkhunter/scripts
UPDATE_LANG="en"
LOGFILE=/var/log/rkhunter.log
USE_SYSLOG=authpriv.warning
AUTO_X_DETECT=1
ENABLE_TESTS=all
DISABLE_TESTS=deleted_files
HASH_CMD=sha256sum
SCRIPTWHITELIST=/bin/egrep
SCRIPTWHITELIST=/bin/fgrep
SCRIPTWHITELIST=/bin/which
SCRIPTWHITELIST=/usr/bin/ldd
SCRIPTWHITELIST=/usr/sbin/adduser
ALLOWPROCLISTEN=/sbin/dhclient
WEB_CMD=curl
DISABLE_UNHIDE=1
INSTALLDIR=/usr
EOF
	cat <<\EOF | sudo tee /etc/default/rkhunter
CRON_DAILY_RUN="yes"
CRON_DB_UPDATE="yes"
DB_UPDATE_EMAIL="yes"
REPORT_EMAIL="root"
APT_AUTOGEN="yes"
NICE="0"
RUN_CHECK_ON_BATTERY="yes"
EOF
	sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.old
	if egrep -q '^\s*PermitRootLogin\s*' /etc/ssh/sshd_config; then
		sudo sed -i "s/^\s*PermitRootLogin\s*yes/PermitRootLogin no/g" /etc/ssh/sshd_config
	else
		echo 'PermitRootLogin no' | sudo tee -a /etc/ssh/sshd_config
	fi
	if egrep -q '^\s*Protocol\s*' /etc/ssh/sshd_config; then
		sudo sed -i "s/^\s*Protocol\s*[0-9,]*/Protocol 2/g" /etc/ssh/sshd_config
	else
		echo 'Protocol 2' | sudo tee -a /etc/ssh/sshd_config
	fi
}

INSTALLLOG=`mktemp`
function ProcessError(){
  echo >&2 "Error while setup. Install log located in file $INSTALLLOG.
Please contact @640kilobyte on official ZenCash Discord  channel or ZenCash channel at Telegram messenger."
Last 5 lines:
`tail -n5 $INSTALLLOG`" 
}

command -v lsb_release  >/dev/null 2>&1 || ExitErrorMessage "I require lsb-release package. Run 'sudo apt-get install lsb-release' and start again."
[ -z "$1" ] && ExitErrorMessage "Usage: $0 this_server_fqdn"
FQDN=$1

[[ $USER == "root" ]] && ExitErrorMessage "Setup and running ZenCash node from root insecure, can't contine.
Please add new user (here 'zuser' for example):
   useradd -m -G sudo,systemd-journal,adm -s /bin/bash zuser
Set user password:
   passwd zuser
And login via ssh or:
   su - zuser"

DetectOS
WelcomeScreen
ScreenSpacer
echo "Used FQDN $FQDN. Install log located in file $INSTALLLOG"
echo "Enter password if you see request. I hope sudo will no ask for password every run :)"
sudo true || ExitErrorMessage "sudo error. Check password or sudoers"
ScreenSpacer

trap ProcessError EXIT HUP INT QUIT TERM

set -e

echo -n "Make swap if need..."
AddSwap &>> $INSTALLLOG
echo "DONE"

echo -n "Setting hostname..."
SetHostname &>> $INSTALLLOG
echo "DONE"

echo -n "Install software..."
SoftwareInstall &>> $INSTALLLOG
echo "DONE"

echo -n "Getting certificate..."
GetCert &>> $INSTALLLOG
echo "DONE"

echo -n "Fetch zkSNARK parameters..."
FetchzkSNARK &>> $INSTALLLOG
echo "DONE"

echo -n "Setup zend..."
SetupZend &>> $INSTALLLOG
echo "DONE"

echo -n "Install tracker..."
SetupTracker &>> $INSTALLLOG
echo "DONE"

echo -n "Secure host..."
SimpleSecurity &>> $INSTALLLOG
echo "DONE"

set +e

trap - EXIT HUP INT QUIT TERM

ScreenSpacer
FinalScreen