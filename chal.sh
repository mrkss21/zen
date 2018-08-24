#!/bin/bash

trkDir="~/nodetracker/"
trkService="zentracker@$USER"
if [[ $( cat ~/nodetracker/config/local/lastExecSec | cut -d. -f1 ) -ge 300 ]]; then
        curl -s https://$(journalctl -u $trkService --no-pager 2>/dev/null | tac | grep -oP -m1 "(?<=Stat check: connected to:)\S*").zensystem.io/$(journalctl -u $trkService --no-pager 2>/dev/null | tac | grep -oP -m1 "(?<=Node t_address \(not for stake\)=)\w+")/$(cat ~/nodetracker/config/config.json | grep -oP "(?<=\"nodeid\": )\d+")/send
fi
