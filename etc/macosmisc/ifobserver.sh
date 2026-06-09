#!/bin/bash

INTERFACE=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interface)
            INTERFACE="$2"
            INTERFACE=$(echo "$INTERFACE" | awk '{print tolower($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --interface <en0|..>"
            exit 1 ;;
    esac
done

if [[ -z "$INTERFACE" ]]; then
    echo "Error: Arguments --interface and --action are required."
    echo "Usage: $0 --interface en0"
    exit 1
fi


##

MY_IP_IS_PRIVATE="false"
MY_IP=$(ifconfig $INTERFACE | awk '/inet / {print $2}')
if [[ "$MY_IP" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    MY_IP_IS_PRIVATE="true"
fi

_dhcpcomment() {
    /etc/macosmisc/pfmanager.sh --tag @DHCP_IN --action COMMENT
    /etc/macosmisc/pfmanager.sh --tag @DHCP_OUT --action COMMENT
}
_dhcpuncomment() {
    /etc/macosmisc/pfmanager.sh --tag @DHCP_IN --action UNCOMMENT
    /etc/macosmisc/pfmanager.sh --tag @DHCP_OUT --action UNCOMMENT
}

if [ "$MY_IP_IS_PRIVATE" == "true" ]; then
    _dhcpcomment
else
    _dhcpuncomment
    if [[ "$MY_IP" =~ ^169\.254\. ]]; then
        sleep 20
        /etc/macosmisc/ifmanager.sh --action RANDOM_MAC --include $INTERFACE
        /etc/macosmisc/ifmanager.sh --action UP --include $INTERFACE
        scutil --renew $INTERFACE >/dev/null 2>&1
    fi   
fi

