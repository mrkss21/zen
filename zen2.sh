sudo apt-get update && sudo apt-get -y upgrade
sudo apt -y install pwgen
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo su -
cat <<EOF >> /etc/fstab
/swapfile none swap sw 0 0
EOF
exit
sudo su -
cat <<EOF >> /etc/sysctl.conf
vm.swappiness=10
EOF
exit
sudo apt-get install -y apt-transport-https lsb-release
echo 'deb https://zencashofficial.github.io/repo/ '$(lsb_release -cs)' main' | sudo tee --append /etc/apt/sources.list.d/zen.list
gpg --keyserver ha.pool.sks-keyservers.net --recv 219F55740BBF7A1CE368BA45FB7053CE4991B669
gpg --export 219F55740BBF7A1CE368BA45FB7053CE4991B669 | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y zen # to install Zen
zen-fetch-params
zend
USERNAME=$(pwgen -s 16 1)
PASSWORD=$(pwgen -s 64 1)
cat <<EOF > ~/.zen/zen.conf
rpcuser=$USERNAME
rpcpassword=$PASSWORD
rpcport=18231
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
txindex=1
logtimestamps=1
onlynet=ipv4
EOF
zend
sudo apt install socat
git clone https://github.com/Neilpang/acme.sh.git
cd acme.sh
./acme.sh --install
zen-cli getinfo
