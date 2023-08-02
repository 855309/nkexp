#!/bin/bash

bssid="null"

s_info () {
    printf "Title"
    exit 0
}

start () {
    # ...
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
        fi

        shift
    done

    if [ $bssid = "null" ]
    then
        printf "BSSID not found.\n"
        exit 0
    fi

    start
}

main $@