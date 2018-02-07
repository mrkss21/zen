sudo apt -y install npm
sudo npm install -g n
sudo n latest
sudo apt -y install make
mkdir ~/zencash
cd ~/zencash
git clone https://github.com/ZencashOfficial/secnodetracker.git
cd secnodetracker
npm install
git remote set-url origin https://github.com/ZencashOfficial/secnodetracker.git
git remote -v
git fetch origin
git checkout master
git pull
cd ~/zencash/secnodetracker/
sudo npm install pm2 -g
sudo apt install monit
sudo apt -y install ufw
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh/tcp
sudo ufw limit ssh/tcp
sudo ufw allow http/tcp
sudo ufw allow https/tcp
sudo ufw allow 9033/tcp
sudo ufw logging on
sudo apt -y install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo apt -y install rkhunter
