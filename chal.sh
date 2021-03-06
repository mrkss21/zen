#!/bin/bash

trkDir="$HOME/nodetracker/"
trkService="zentracker@$USER"
waitForRestart="20s"
maxAllowChallenge="300"

function getUrlData(){
  currSrv=$(journalctl -u $trkService --no-pager 2>/dev/null | tac  | grep -oP -m1 "(?<=Connected to server |connected to:)\w*\.\w*")
  currTa=$(journalctl -u $trkService --no-pager 2>/dev/null | tac | grep -oP -m1 "(?<=Node t_address \(not for stake\)=)\w+")
  currNid=$(cat $trkDir/config/config.json | grep -oP "(?<=\"nodeid\": )\d+")
}

currLastExec=$( cat $trkDir/config/local/lastExecSec | cut -d. -f1 )
if [[ $currLastExec -ge $maxAllowChallenge ]]; then
  getUrlData  
  if [[ -z "$currSrv" ]] || [[ -z "$currTa" ]] || [[ -z "$currNid" ]]; then
    tkrPid=$(systemctl status $trkService | grep -oP "(?<=PID: )\d+")
    kill $tkrPid
    sleep $waitForRestart
    getUrlData
  fi
        curl -s https://$currSrv.zensystem.io/$currTa/$currNid/send
fi
