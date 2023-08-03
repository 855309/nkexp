#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
bold=$(tput bold)
tdef=$(tput sgr0)

bssid="null"
ch="null"

s_info () {
    printf "WPS Pixiedust Attack"
    exit 0
}

start () {
    # ...
    printf "Started attack to ${bold}${bssid}${tdef}.\n"
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