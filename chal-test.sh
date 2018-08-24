	cat << EOF | sudo tee /home/znode/chal.sh
#!/bin/bash
trkDir="~/nodetracker/"
trkService="zentracker@$USER"
if [[ $( cat $trkDir/config/local/lastExecSec | cut -d. -f1 ) -ge 300 ]]; then
        curl -s https://$(journalctl -u $trkService --no-pager 2>/dev/null | tac | grep -oP -m1 "(?<=Stat check: connected to:)\S*").zensystem.io/$(journalctl -u $trkService --no-pager 2>/dev/null | tac | grep -oP -m1 "(?<=Node t_address \(not for stake\)=)\w+")/$(cat ~$trkDir/config/config.json | grep -oP "(?<=\"nodeid\": )\d+")/send
fi
EOF
chmod 777 chal.sh
crontab -l > tempcron
echo "*/15 * * * * /home/znode/chal.sh" >> tempcron
crontab tempcron
rm tempcron
