#!/bin/bash

declare -a btin
declare -a btin_path
declare -a attack
declare -a attack_path

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
bold=$(tput bold)
tdef=$(tput sgr0)

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

imode=""

update_imode () {
    if [ "${interface%%mon}" != "$interface" ]
    then
        imode="monitor"
    else
        imode="managed"
    fi
}

# BUILTIN TOOLS

ap_scanner () {
    if [ $imode != "monitor" ]
    then
        printf "Monitor mode is needed for this tool.\n\n"
        return
    fi

    declare -a scan_bssid
    declare -a scan_ch
    declare -a scan_power
    declare -a scan_wps
    declare -a scan_vendor
    declare -a scan_ssid
    declare -i ix
    ix=0

    scfile="scan.out"
    [ -e "$scfile" ] && rm -f $scfile

    xterm -fg white -bg black -e "wash -i ${interface} -aUF | tee ${scfile}" &> /dev/null &
    xtpid=$!

    read -p "Press Return when you see the target network.  "

    kill $xtpid

    # 20:08:89:72:FF:A6 8 -61 2.0 No Unknown SSID
    # 20:08:89:72:FF:A6 8 -61 Unknown SSID

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

    printf "Select AP:\n\n"
    printf "       ${bold}BSSID              Ch  dBm  WPS       Vendor    ESSID${tdef}\n"
    for i in $(seq 0 $((${#scan_bssid[@]} - 1)))
    do
        wln=$((5 - ${#i}))
        [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
        printf "${bold}${i})${tdef} ${scan_bssid[${i}]}  ${scan_ch[${i}]}"
        wln=$((2 - ${#scan_ch[${i}]}))
        [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
        printf "  ${scan_power[${i}]}  "
        if [ ${scan_wps[${i}]} = "enabled" ]
        then
            printf $green
        elif [ ${scan_wps[${i}]} = "locked" ]
        then
            printf $red
        else
            printf $yellow
        fi
        printf "${scan_wps[${i}]}${tdef}"
        wln=$((8 - ${#scan_wps[${i}]}))
        [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
        printf "  ${scan_vendor[${i}]}"
        wln=$((8 - ${#scan_vendor[${i}]}))
        [[ $wln != 0 ]] && printf " %.0s" $(seq 1 ${wln})
        printf "  ${scan_ssid[${i}]}\n"
    done

    printf "\n"

    get_int_range 0 $((${#scan_bssid[@]} - 1))

    sel_netw="${scan_bssid[${input}]}"
    sel_netw_ssid="${scan_ssid[${input}]}"
    sel_netw_wps="${scan_wps[${input}]}"
    sel_netw_ch="${scan_ch[${input}]}"
    
    printf "\n"
}

iface_monitor () {
    airmon-ng start "$interface" &> /dev/null
    interface="${interface}mon"
    imode="monitor"
    printf "Autoselected interface to ${bold}${interface}${tdef}.\n"
    
    printf "Done.\n"
}

iface_managed () {
    airmon-ng stop "$interface" &> /dev/null
    interface="${interface%%mon}"
    imode="managed"
    printf "Autoselected interface to ${bold}${interface}${tdef}.\n"
    
    printf "Done.\n"
}

exit_script () {
    if [ "$imode" != "managed" ]
    then
        printf "Do you want to restore the interface to managed mode? [Y/n]\n"
        get_yn_y

        if [ $input = "y" ]
        then
            iface_managed
        fi
        printf "\n"
    fi

    exit 0
}

# END BUILTIN TOOLS

get_input () {
    read -p "${green}${bold}>${tdef} " input
}

get_int_range () {
    get_input
    while [ "$input" -lt $1 ] || [ $2 -lt "$input" ]
    do
        printf "Invalid input.\n\n"
        get_input
    done
}

get_yn_y () {
    get_input
    if [ "$input" = "Y" ] || [ "$input" = "y" ] || [ "$input" = "" ]
    then
        input="y"
    elif [ "$input" = "N" ] || [ "$input" = "n" ]
    then
        input="n"
    else
        get_yn_y
    fi
}

get_yn_n () {
    get_input
    if [ "$input" = "Y" ] || [ "$input" = "y" ]
    then
        input="y"
    elif [ "$input" = "N" ] || [ "$input" = "n" ] || [ "$input" = "" ]
    then
        input="n"
    else
        get_yn_n
    fi
}

select_interface () {
    declare -a ifaces

    for i in $(ifconfig -a -s | cut -d ' ' -f1)
    do
        if [ "$i" != "Iface" ]
        then
            ifaces+=("$i")
        fi
    done

    echo "Select network interface: "
    ix=0
    for i in $(seq $ix $((${#ifaces[@]} - 1)))
    do
        printf "    $i) ${ifaces[i]}\n"
    done

    printf "\n"

    get_int_range 0 $((${#ifaces[@]} - 1))

    interface=${ifaces[$input]}
    printf "\nInterface ${bold}${interface}${tdef} selected.\n"

    update_imode

    sleep 1
}

register_tools () {
    btin+=("Exit script")
    btin_path+=("exit_script")
    btin+=("WiFi AP Scanner")
    btin_path+=("ap_scanner")
    btin+=("Set interface mode to Monitor")
    btin_path+=("iface_monitor")
    btin+=("Set interface mode to Managed")
    btin_path+=("iface_managed")

    for ent in "${SCRIPT_DIR}/tools"/*.sh
    do
        attack+=("$($ent --info)")
        attack_path+=($ent)
    done

    sel_netw="[null]"
    sel_netw_ssid="[null]"
    sel_netw_wps="[null]"
    sel_netw_ch="[null]"
}

tool_menu () {
    clear

    printf "       _\n"
    printf "      | |\n"
    printf " ____ | |  _ _____ _   _ ____\n"
    printf "|  _ \\| |_/ ) ___ ( \\ / )  _ \\ \n"
    printf "| | | |  _ (| ____|) X (| |_| |\n"
    printf "|_| |_|_| \\_)_____|_/ \\_)  __/\n"
    printf "                        |_|\n\n"


    printf "Selected interface:\n"
    printf "    Name:  ${bold}${interface}${tdef}\n"
    printf "    Mode:  ${bold}${imode}${tdef}\n\n"
    printf "Selected network:\n"
    printf "    SSID:  ${bold}${sel_netw_ssid}${tdef}\n"
    printf "    BSSID: ${bold}${sel_netw}${tdef}\n"
    printf "    CH:    ${bold}${sel_netw_ch}${tdef}\n"
    printf "    WPS:   ${bold}"
    if [ $sel_netw_wps = "enabled" ]
    then
        printf $green
    elif [ $sel_netw_wps = "locked" ]
    then
        printf $red
    else
        printf $yellow
    fi
    printf "${sel_netw_wps}${tdef}\n"
    
    printf "\n"

    printf "Built-in tools:\n"
    for i in $(seq 0 $((${#btin[@]} - 1)))
    do
        printf "    ${bold}${i})${tdef} ${btin[${i}]}\n"
    done

    printf "\n"

    printf "Attack tools:\n"
    for i in $(seq 0 $((${#attack[@]} - 1)))
    do
        printf "    ${bold}$((${i} + ${#btin[@]})))${tdef} ${attack[${i}]}\n"
    done

    printf "\n"

    get_int_range 0 $((${#attack[@]} + ${#btin[@]} - 1))

    clear

    eid=$input
    if [ "$input" -ge "${#btin[@]}" ]
    then
        eid=$((${input} - ${#btin[@]}))
        ${attack_path[${eid}]} --iface ${interface} --bssid ${sel_netw} --ch ${sel_netw_ch}
    else
        ${btin_path[${eid}]}
    fi

    # xterm -hold -fg white -bg black -e "${rcmd}"
    
    read -p "Press Return to continue..."

    tool_menu
}

main () {
    clear

    if [ "$EUID" != 0 ]
    then 
        printf "${bold}This script requires root access.${tdef}\n"
        exit
    fi

    select_interface
    
    register_tools

    tool_menu
}

main