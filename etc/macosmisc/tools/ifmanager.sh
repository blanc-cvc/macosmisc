#!/bin/bash

LOG_FILE=""
IFS_ACTION=""
IFS_EXCLUDED=()
IFS_INCLUDED=()

RANDOM_IPS_EXCLUDED=()
RANDOM_MAC_EXCLUDED=()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# sourced functions start with _
source "$SCRIPT_DIR/utils.sh"


while [[ "$#" -gt 0 ]]; do
    case $1 in
        --log)
            LOG_FILE="$2"
            if [ "$LOG_FILE" != "/dev/null" ]; then
                LOG_FILE="$SCRIPT_DIR/../logs/$LOG_FILE.log"
            fi
            shift 2 ;;
        --include)
            IFS_INCLUDED=$(echo "$2" | awk '{print tolower($0)}')
            IFS=',' read -ra IFS_INCLUDED <<< "$IFS_INCLUDED"
            [ "$IFS_INCLUDED" == "hardware" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED"
            [ "$IFS_INCLUDED" == "wifi" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED" "wifi"
            [ "$IFS_INCLUDED" == "ethernet" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED" "ethernet"
            shift 2 ;;
        --exclude)
            IFS_EXCLUDED=$(echo "$2" | awk '{print tolower($0)}')
            IFS=',' read -ra IFS_EXCLUDED <<< "$IFS_EXCLUDED"
            [ "$IFS_EXCLUDED" == "hardware" ] && _utils_wifi_ethernet_interfaces "IFS_EXCLUDED"
            [ "$IFS_EXCLUDED" == "wifi" ] && _utils_wifi_ethernet_interfaces "IFS_EXCLUDED" "wifi"
            [ "$IFS_EXCLUDED" == "ethernet" ] && _utils_wifi_ethernet_interfaces "IFS_EXCLUDED" "ethernet"
            shift 2 ;;
        --action)
            IFS_ACTION="$2"
            IFS_ACTION=$(echo "$IFS_ACTION" | awk '{print toupper($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --action <action> < --exclude en0,en1 || --include en0,en2 >"
            exit 1 ;;
    esac
done

if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="/dev/null"
fi

if [[ -z "$IFS_ACTION" ]] || \
   { [[ -z "$IFS_EXCLUDED" ]] && [[ -z "$IFS_INCLUDED" ]]; } || \
   { [[ -n "$IFS_EXCLUDED" ]] && [[ -n "$IFS_INCLUDED" ]]; }; then
    echo "Error: provide an <action>  AND  <an interface or a list of interfaces>  to be included OR excluded."
    echo "Usage: $0 --action <action> (--exclude <list> OR --include <list>)"
    echo "Example: $0 --action SOMETHING --exclude en0,en2"
    exit 1
fi


##

set_new_ip_mac_of_if() {
    local ip=$(_utils_generate_random_private_ip)
    local mac=$(_utils_generate_random_mac)
    local netmask=$(_utils_generate_random_netmask)
    if ! _utils_is_included "$ip" "${RANDOM_IPS_EXCLUDED[@]}"; then
        echo "$(date +%H:%M:%S) ifmanager: set interface:$1 ip:$ip netmask:$netmask" >> "$LOG_FILE"
        ifconfig $1 $ip netmask $netmask >/dev/null 2>&1
    fi
    if ! _utils_is_included "$mac" "${RANDOM_MAC_EXCLUDED[@]}"; then
        echo "$(date +%H:%M:%S) ifmanager: set interface:$1 mac:$mac" >> "$LOG_FILE"
        ifconfig $1 lladdr $mac >/dev/null 2>&1
    fi
}


##

INTERFACES=$(ifconfig | awk '/^[a-z0-9]+:/{gsub(/:$/, "", $1); print $1}')

## ACTION AIRPORTPREFS
if [ "$IFS_ACTION" == "AIRPORTPREFS" ]; then
    if [ -n "$IFS_INCLUDED" ]; then
        for iface in "${IFS_INCLUDED[@]}"; do
            local prefs=(
                "AWDLEnabled=NO"
                "P2PFirewall=YES"
                "P2PDevicesManaged=NO"
                "DisconnectOnLogout=YES"
                "DisableMultiChannelRanging=YES"
                "OffloadAutoConfigureSleepScan=YES"
                "OffloadAutoConfigureIPAddresses=YES"
                "OffloadSleepScanCycleRestTime=80"
                "RequireAdminIBSS=YES"
            )

            echo "$(date +%H:%M:%S) ifmanager: set interface:$iface airportd prefs" >> "$LOG_FILE"
            for pref in "${prefs[@]}"; do
                /usr/libexec/airportd "$iface" prefs "$pref" >/dev/null 2>&1
            done
        done
    fi
fi

## ACTION RANDOM_MAC
if [ "$IFS_ACTION" == "RANDOM_MAC" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
            mac=$(_utils_generate_random_mac)
            echo "$(date +%H:%M:%S) ifmanager: set interface:$INTERFACE mac:$mac" >> "$LOG_FILE"
            ifconfig $INTERFACE down >/dev/null 2>&1
            ifconfig $INTERFACE lladdr $mac >/dev/null 2>&1
            ifconfig $INTERFACE up >/dev/null 2>&1
            ifconfig $INTERFACE lladdr $mac >/dev/null 2>&1
            ifconfig $INTERFACE down >/dev/null 2>&1
        fi
    done
fi

## ACTION UP
if [ "$IFS_ACTION" == "UP" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
            echo "$(date +%H:%M:%S) ifmanager: set interface:$INTERFACE up" >> "$LOG_FILE"
            ifconfig $INTERFACE up >/dev/null 2>&1
            PORT_NAME=$(networksetup -listallhardwareports | awk -v dev="$INTERFACE" '
                /Hardware Port/ {port=$3; for(i=4; i<=NF; i++) port=port " " $i}
                /Device/ && $2==dev {print port; exit}
            ')
            if [ -n "$PORT_NAME" ]; then
                networksetup -setnetworkserviceenabled "$PORT_NAME" on >/dev/null 2>&1
            fi
        fi
    done
fi

## ACTION DOWN
if [ "$IFS_ACTION" == "DOWN" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
            echo "$(date +%H:%M:%S) ifmanager: set interface:$INTERFACE down" >> "$LOG_FILE"
            ifconfig $INTERFACE down >/dev/null 2>&1
            PORT_NAME=$(networksetup -listallhardwareports | awk -v dev="$INTERFACE" '
                /Hardware Port/ {port=$3; for(i=4; i<=NF; i++) port=port " " $i}
                /Device/ && $2==dev {print port; exit}
            ')
            if [ -n "$PORT_NAME" ]; then
                networksetup -setnetworkserviceenabled "$PORT_NAME" off >/dev/null 2>&1
            fi
        fi
    done
fi

## ACTION CHAOS
if [ "$IFS_ACTION" == "CHAOS" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
            RANDOM_IPS_EXCLUDED+=($(ifconfig $INTERFACE | awk '/inet / {print $2}'))
            RANDOM_MAC_EXCLUDED+=($(ifconfig $INTERFACE | awk '/ether / {print toupper($2)}'))
        fi
    done
    for INTERFACE in $INTERFACES; do
        #STATUS=$(ifconfig "$INTERFACE" | awk '/status:/{print $2; exit}')
        #if [ -z "$STATUS" ]; then
        #    STATUS="unknown"
        #fi
        #echo "Interface: $INTERFACE ($STATUS)"
        ifconfig $INTERFACE inet6 -nud -dad ifdisabled >/dev/null 2>&1
        if [ "$INTERFACE" == "lo0" ]; then
            ifconfig lo0 inet6 ::1 delete >/dev/null 2>&1
            ifconfig lo0 inet6 fe80::1%lo0 delete >/dev/null 2>&1
        else
            if { [[ -n "$IFS_EXCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
               { [[ -n "$IFS_INCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
                echo "$(date +%H:%M:%S) ifmanager: set interface:$INTERFACE chaos" >> "$LOG_FILE"
                ifconfig $INTERFACE down >/dev/null 2>&1
                set_new_ip_mac_of_if $INTERFACE
                ifconfig $INTERFACE -rxcsum -txcsum -tso -lro >/dev/null 2>&1
                ifconfig $INTERFACE up >/dev/null 2>&1
                set_new_ip_mac_of_if $INTERFACE
                ifconfig $INTERFACE -rxcsum -txcsum -tso -lro >/dev/null 2>&1
                ifconfig $INTERFACE down >/dev/null 2>&1
                if [[ "$INTERFACE" =~ ^gif ]] || [[ "$INTERFACE" =~ ^stf ]]; then
                    ifconfig $INTERFACE mtu $(_utils_generate_random_int 1400 4000) >/dev/null 2>&1
                else
                    ifconfig $INTERFACE mtu $(_utils_generate_random_int 100 400) >/dev/null 2>&1
                fi
            fi
        fi
        PORT_NAME=$(networksetup -listallhardwareports | awk -v dev="$INTERFACE" '
            /Hardware Port/ {port=$3; for(i=4; i<=NF; i++) port=port " " $i}
            /Device/ && $2==dev {print port; exit}
        ')
        if [ -n "$PORT_NAME" ]; then
            networksetup -setv6off "$PORT_NAME" >/dev/null 2>&1 # apply to every ports
            if { [[ -n "$IFS_EXCLUDED" ]] && ! _utils_is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
               { [[ -n "$IFS_INCLUDED" ]] && _utils_is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
                networksetup -setv4off "$PORT_NAME" >/dev/null 2>&1
                networksetup -setnetworkserviceenabled "$PORT_NAME" off >/dev/null 2>&1
            fi
        fi
        if [[ "$INTERFACE" =~ ^bridge ]]; then
            BRIDGE_MEMBERS=$(ifconfig $INTERFACE | awk '/^[\t ]*member:/ {print $2}')
            BRIDGE_MAC=$(ifconfig $INTERFACE | awk '/ether/ {print $2}')
            if [ -n "$BRIDGE_MEMBERS" ]; then
                for BRIDGE_MEMBER in $BRIDGE_MEMBERS; do
                    ifconfig $INTERFACE timeout 1 >/dev/null 2>&1
                    ifconfig $INTERFACE maxaddr 0 >/dev/null 2>&1
                    ifconfig $INTERFACE -learn $BRIDGE_MEMBER >/dev/null 2>&1
                    ifconfig $INTERFACE -discover $BRIDGE_MEMBER >/dev/null 2>&1
                    if [ -n "$BRIDGE_MAC" ]; then
                        ifconfig $INTERFACE hostfilter $BRIDGE_MEMBER $BRIDGE_MAC >/dev/null 2>&1
                    fi
                    ifconfig $INTERFACE hostfilter $BRIDGE_MEMBER 127.0.0.1 >/dev/null 2>&1
                done
            fi
        fi
    done
fi


