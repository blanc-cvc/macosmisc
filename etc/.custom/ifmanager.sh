#!/bin/bash

IFS_ACTION=""
IFS_EXCLUDED=()
IFS_INCLUDED=()

RANDOM_IPS_EXCLUDED=()
RANDOM_MAC_EXCLUDED=()

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --include)
            IFS_INCLUDED=$(echo "$2" | awk '{print tolower($0)}')
            IFS=',' read -ra IFS_INCLUDED <<< "$IFS_INCLUDED"
            shift 2 ;;
        --exclude)
            IFS_EXCLUDED=$(echo "$2" | awk '{print tolower($0)}')
            IFS=',' read -ra IFS_EXCLUDED <<< "$IFS_EXCLUDED"
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

if [[ -z "$IFS_ACTION" ]] || \
   { [[ -z "$IFS_EXCLUDED" ]] && [[ -z "$IFS_INCLUDED" ]]; } || \
   { [[ -n "$IFS_EXCLUDED" ]] && [[ -n "$IFS_INCLUDED" ]]; }; then
    echo "Error: provide an <action>  AND  <an interface or a list of interfaces>  to be included OR excluded."
    echo "Usage: $0 --action <action> (--exclude <list> OR --include <list>)"
    echo "Example: $0 --action SOMETHING --exclude en0,en2"
    exit 1
fi


##

is_included() {
    local target="$1"
    shift
    local list=("$@")
    for item in "${list[@]}"; do
        if [[ "$item" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

generate_random_int() {
    local min=${1:-100}
    local max=${2:-800}
    echo $(( RANDOM % (max - min + 1) + min ))
}

generate_random_mac() {
    local mac=$(od -An -N6 -tx1 /dev/urandom | tr -d ' \n')
    local first_byte=${mac:0:2}
    local first_char=${first_byte:0:1}
    local dec=$((16#$first_char))
    dec=$(( (dec | 2) & ~1 ))
    local new_first_char=$(printf '%x' $dec)
    mac="${new_first_char}${first_byte:1:1}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
    echo "$mac" | awk '{print toupper($0)}'
}

generate_random_private_ip() {
    local type=$((RANDOM % 3))
    case $type in
        0) echo "10.$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))" ;;
        1) echo "172.$((16 + RANDOM % 16)).$((RANDOM % 256)).$((RANDOM % 256))" ;;
        2) echo "192.168.$((RANDOM % 256)).$((RANDOM % 256))" ;;
    esac
}

generate_random_netmask() {
    local cidr=$((RANDOM % 30 + 1))
    local mask=""
    local full_octets=$((cidr / 8))
    local remainder=$((cidr % 8))
    for i in {1..4}; do
        if [ $i -le $full_octets ]; then
            mask+="255"
        elif [ $i -eq $((full_octets + 1)) ]; then
            local val=$(( 256 - (1 << (8 - remainder)) ))
            mask+="$val"
        else
            mask+="0"
        fi
        if [ $i -lt 4 ]; then mask+="."; fi
    done
    echo "$mask"
}

set_new_ip_mac_of_if() {
    NEW_IP=$(generate_random_private_ip)
    NEW_MAC=$(generate_random_mac)
    if ! is_included "$NEW_IP" "${RANDOM_IPS_EXCLUDED[@]}"; then
        ifconfig $1 $NEW_IP netmask $(generate_random_netmask) >/dev/null 2>&1
    fi
    if ! is_included "$NEW_MAC" "${RANDOM_MAC_EXCLUDED[@]}"; then
        ifconfig $1 lladdr $NEW_MAC >/dev/null 2>&1
    fi
}


##

INTERFACES=$(ifconfig | awk '/^[a-z0-9]+:/{gsub(/:$/, "", $1); print $1}')


## ACTION RANDOM_MAC
if [ "$IFS_ACTION" == "RANDOM_MAC" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
            ifconfig $INTERFACE down >/dev/null 2>&1
            ifconfig $INTERFACE lladdr $(generate_random_mac) >/dev/null 2>&1
            ifconfig $INTERFACE up >/dev/null 2>&1
            ifconfig $INTERFACE lladdr $(generate_random_mac) >/dev/null 2>&1
            ifconfig $INTERFACE down >/dev/null 2>&1
        fi
    done
fi

## ACTION UP
if [ "$IFS_ACTION" == "UP" ]; then
    for INTERFACE in $INTERFACES; do
        if { [[ -n "$IFS_EXCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
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
        if { [[ -n "$IFS_EXCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
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
        if { [[ -n "$IFS_EXCLUDED" ]] && is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
           { [[ -n "$IFS_INCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
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
            if { [[ -n "$IFS_EXCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
               { [[ -n "$IFS_INCLUDED" ]] && is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
                ifconfig $INTERFACE down >/dev/null 2>&1
                set_new_ip_mac_of_if $INTERFACE
                ifconfig $INTERFACE -rxcsum -txcsum -tso -lro >/dev/null 2>&1
                ifconfig $INTERFACE up >/dev/null 2>&1
                set_new_ip_mac_of_if $INTERFACE
                ifconfig $INTERFACE -rxcsum -txcsum -tso -lro >/dev/null 2>&1
                ifconfig $INTERFACE down >/dev/null 2>&1
                if [[ "$INTERFACE" =~ ^gif ]] || [[ "$INTERFACE" =~ ^stf ]]; then
                    ifconfig $INTERFACE mtu $(generate_random_int 1400 4000) >/dev/null 2>&1
                else
                    ifconfig $INTERFACE mtu $(generate_random_int 100 400) >/dev/null 2>&1
                fi
            fi
        fi
        PORT_NAME=$(networksetup -listallhardwareports | awk -v dev="$INTERFACE" '
            /Hardware Port/ {port=$3; for(i=4; i<=NF; i++) port=port " " $i}
            /Device/ && $2==dev {print port; exit}
        ')
        if [ -n "$PORT_NAME" ]; then
            networksetup -setv6off "$PORT_NAME" >/dev/null 2>&1 # apply to every ports
            if { [[ -n "$IFS_EXCLUDED" ]] && ! is_included "$INTERFACE" "${IFS_EXCLUDED[@]}"; } || \
               { [[ -n "$IFS_INCLUDED" ]] && is_included "$INTERFACE" "${IFS_INCLUDED[@]}"; }; then
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


