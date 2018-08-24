wget https://raw.githubusercontent.com/mrkss21/zen/master/chal.sh
chmod 777 chal.sh
crontab -l > tempcron
echo "*/15 * * * * /home/znode/chal.sh" >> tempcron
crontab tempcron
rm tempcron
