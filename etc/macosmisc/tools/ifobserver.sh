#!/bin/bash

IFS_INCLUDED=""
IFS_ACTION=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# sourced functions start with _
source "$SCRIPT_DIR/utils.sh"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface)
            IFS_INCLUDED=$(echo "$2" | awk '{print tolower($0)}')
            IFS=',' read -ra IFS_INCLUDED <<< "$IFS_INCLUDED"
            [ "$IFS_INCLUDED" == "hardware" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED"
            [ "$IFS_INCLUDED" == "wifi" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED" "wifi"
            [ "$IFS_INCLUDED" == "ethernet" ] && _utils_wifi_ethernet_interfaces "IFS_INCLUDED" "ethernet"
            shift 2 ;;
        --action)
            IFS_ACTION="$2"
            IFS_ACTION=$(echo "$IFS_ACTION" | awk '{print toupper($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --interface <en0|..>"
            exit 1 ;;
    esac
done

if [[ -z "$IFS_INCLUDED" ]]; then
    echo "Error: Argument --interface is required."
    echo "Usage: $0 --interface en0"
    exit 1
fi


##

if [ "$IFS_ACTION" == "WATCHDHCP" ]; then
    for iface in "${IFS_INCLUDED[@]}"; do
        MY_IP_IS_PRIVATE="false"
        MY_IP=$(ifconfig $iface | awk '/inet / {print $2}')
        if [[ "$MY_IP" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
            MY_IP_IS_PRIVATE="true"
        fi
        if [ "$MY_IP_IS_PRIVATE" == "true" ]; then
            /bin/bash "$SCRIPT_DIR/pfmanager.sh" --action COMMENT --tag "@DHCP_,@IF_$iface"
        else
            /bin/bash "$SCRIPT_DIR/ifmanager.sh" --action RANDOM_MAC --include $iface
            /bin/bash "$SCRIPT_DIR/ifmanager.sh" --action UP --include $iface
            /bin/bash "$SCRIPT_DIR/pfmanager.sh" --action UNCOMMENT --tag "@DHCP_,@IF_$iface"
            if [[ "$MY_IP" =~ ^169\.254\. ]]; then
                sleep 10
                scutil --renew $iface >/dev/null 2>&1
            fi   
        fi
    done
fi

