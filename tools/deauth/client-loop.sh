#!/bin/bash

declare -a clients

cl_list="clients-01.csv"
cl_pure="clients.txt"

macrgx="^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$"

bssid="null"

update_clients () {
    clients=()
    while read -r line
    do
        IFS=','
        read -ra ndata <<< "$line"
        if [[ "${ndata[0]}" =~ $macrgx ]]
        then
            if [[ "${ndata[0]}" != "$bssid" ]]
            then
                clients+=("${ndata[0]}")
            fi
        fi
    done < $cl_list

    printf "${clients[@]}" > "$cl_pure"
}

main () {
    [ -e "$cl_pure" ] && rm -f "$cl_pure"
    bssid=$1
    while :
    do
        sleep 2
        update_clients
    done
}

main $@