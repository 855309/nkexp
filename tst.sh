#!/bin/bash

declare -a scan_bssid
declare -a scan_ch
declare -a scan_power
declare -a scan_wps
declare -a scan_vendor
declare -a scan_ssid
declare -i ix
ix=0

scfile="scan.out"
wver="^[0-9]*[.][0-9]*$"
macrgx="^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$"
while read -r line                                                                                                                                                                                                                 
do
    ndata=($line)
    if [[ "${ndata[0]}" =~ $macrgx ]]
    then
        scan_bssid+=("${ndata[0]}")
        scan_ch+=("${ndata[1]}")
        scan_power+=("${ndata[2]}")
        if [[ "${ndata[3]}" =~ $wver ]]
        then
            if [ "${ndata[4]}" = "Yes" ]
            then
                scan_wps+=("locked")
            else
                scan_wps+=("enabled")
            fi
            scan_vendor+=("${ndata[5]}")
            scan_ssid["$ix"]="${ndata[@]:6:${#ndata[@]}}"
        else
            scan_wps+=("disabled")
            scan_vendor+=("${ndata[3]}")
            scan_ssid["$ix"]="${ndata[@]:4:${#ndata[@]}}"
        fi
        ix+=1
    fi
done < $scfile
printf "Select AP:\n"
printf "       ${bold}BSSID              Ch  dBm  WPS       Vendor      ESSID${tdef}\n"
for i in $(seq 0 $((${#scan_bssid[@]} - 1)))
do
    wln=$((5 - ${#i}))
    [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
    printf "${bold}${i})${tdef} ${scan_bssid[${i}]}  ${scan_ch[${i}]}"
    wln=$((2 - ${#scan_ch[${i}]}))
    [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
    printf "  ${scan_power[${i}]}  ${scan_wps[${i}]}"
    wln=$((8 - ${#scan_wps[${i}]}))
    [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
    printf "  ${scan_vendor[${i}]}"
    wln=$((10 - ${#scan_vendor[${i}]}))
    [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
    printf "  ${scan_ssid[${i}]}\n"
done

echo "${#scan_ch[${1}]}"