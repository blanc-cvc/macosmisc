#!/bin/bash

IFS_INCLUDED=""

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
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --interface <en0|..>"
            exit 1 ;;
    esac
done

if [[ -z "$IFS_INCLUDED" ]]; then
    echo "Error: Arguments --interface and --action are required."
    echo "Usage: $0 --interface en0"
    exit 1
fi


##

MY_IP_IS_PRIVATE="false"
MY_IP=$(ifconfig $IFS_INCLUDED | awk '/inet / {print $2}')
if [[ "$MY_IP" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    MY_IP_IS_PRIVATE="true"
fi

_dhcpcomment() {
    /bin/bash "$SCRIPT_DIR/pfmanager.sh" --action COMMENT --tag @DHCP_
}
_dhcpuncomment() {
    /bin/bash "$SCRIPT_DIR/pfmanager.sh" --action UNCOMMENT --tag @DHCP_
}

if [ "$MY_IP_IS_PRIVATE" == "true" ]; then
    _dhcpcomment
else
    /bin/bash "$SCRIPT_DIR/ifmanager.sh" --action RANDOM_MAC --include $IFS_INCLUDED
    /bin/bash "$SCRIPT_DIR/ifmanager.sh" --action UP --include $IFS_INCLUDED
    _dhcpuncomment
    if [[ "$MY_IP" =~ ^169\.254\. ]]; then
        sleep 10
        scutil --renew $IFS_INCLUDED >/dev/null 2>&1
    fi   
fi

