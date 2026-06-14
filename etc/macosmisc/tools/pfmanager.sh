#!/bin/bash

PF_FILE=""
if [[ "$(id -u)" == "0" ]]; then
    PF_FILE="/etc/pf.conf"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PF_FILE="$SCRIPT_DIR/../../pf.conf.test"
fi

MAX_ROTATION=9


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# sourced functions start with _
source "$SCRIPT_DIR/utils.sh"

##

PF_TAG=""
PF_ACTION=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --tag)
            PF_TAG="$2"
            PF_TAG="@${PF_TAG#@}"
            PF_TAG=$(echo "$PF_TAG" | awk '{print toupper($0)}')
            shift 2 ;;
        --action)
            PF_ACTION="$2"
            PF_ACTION=$(echo "$PF_ACTION" | awk '{print toupper($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --tag <PF_TAG> --action <comment|uncomment>"
            exit 1 ;;
    esac
done

if [ "$PF_ACTION" != "BLOCKALL" ] && [ "$PF_ACTION" != "ENABLE" ] && [ "$PF_ACTION" != "DISABLEALF" ] && [ "$PF_ACTION" != "INITRULES" ] && [ "$PF_ACTION" != "UNCOMMENT_AUTO_DNSTYPE" ]; then
    if [[ -z "$PF_TAG" ]] || [[ -z "$PF_ACTION" ]]; then
        echo "Error: Arguments --tag and --action are required."
        echo "Usage: $0 --tag @DENY --action comment"
        exit 1
    fi
fi


##

cp "$PF_FILE" "${PF_FILE}.new"

comment() {
    sed -i '' "/^[^#].*${PF_TAG}.*/ s/^/#/" "${PF_FILE}.new"
}
uncomment() {
    sed -i '' "/^#.*${PF_TAG}.*/ { /\$extif/! s/^#[[:space:]]*//; }" "${PF_FILE}.new"
}
remove() {
    sed -i '' "/${PF_TAG}.*/ { /\$extif/! d; }" "${PF_FILE}.new"
}


if [ "$PF_ACTION" == "COMMENT" ]; then
    comment
elif [ "$PF_ACTION" == "UNCOMMENT" ]; then
    uncomment
elif [ "$PF_ACTION" == "REMOVE" ]; then
    remove
elif [ "$PF_ACTION" == "DISABLEALF" ]; then
    /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off >/dev/null 2>&1
elif [ "$PF_ACTION" == "ENABLE" ]; then
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.conf >/dev/null 2>&1
elif [ "$PF_ACTION" == "BLOCKALL" ]; then
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.blockall.conf >/dev/null 2>&1
elif [ "$PF_ACTION" == "INITRULES" ]; then
    IFS_INCLUDED=""
    _utils_wifi_ethernet_interfaces "IFS_INCLUDED"
    _utils_pf_init_rules "${IFS_INCLUDED[@]}"
elif [ "$PF_ACTION" == "UNCOMMENT_AUTO_DNSTYPE" ]; then
    DNS_TYPE=$(_utils_detect_dns_type)
    if [ "$DNS_TYPE" == "DoH" ]; then
        PF_TAG="@DNS_DOH" && uncomment
        PF_TAG="@DNS_DOT" && comment
        PF_TAG="@DNS_DNS" && comment
    elif [ "$DNS_TYPE" == "DoT" ]; then
        PF_TAG="@DNS_DOH" && comment
        PF_TAG="@DNS_DOT" && uncomment
        PF_TAG="@DNS_DNS" && comment
    elif [ "$DNS_TYPE" == "Do53" ]; then
        PF_TAG="@DNS_DOH" && comment
        PF_TAG="@DNS_DOT" && comment
        PF_TAG="@DNS_DNS" && uncomment
    else
        PF_TAG="@DNS_DOH" && comment
        PF_TAG="@DNS_DOT" && comment
        PF_TAG="@DNS_DNS" && comment
    fi
    
    echo "$DNS_TYPE"

else
    exit 1
fi

if ! pfctl -nf "${PF_FILE}.new" 2>/dev/null; then
    echo "ERROR: Invalid new pf.conf ! Abort."
    mv "${PF_FILE}.new" "${PF_FILE}.invalid"
    exit 1
fi

HASH_CURRENT=$(md5 -q "$PF_FILE" 2>/dev/null || md5sum "$PF_FILE" | cut -d' ' -f1)
HASH_NEW=$(md5 -q "${PF_FILE}.new" 2>/dev/null || md5sum "${PF_FILE}.new" | cut -d' ' -f1)
if [ "$HASH_CURRENT" != "$HASH_NEW" ]; then
    for (( i=MAX_ROTATION-1; i>=1; i-- )); do
        j=$((i+1))
        [ -f "${PF_FILE}.${i}" ] && mv "${PF_FILE}.${i}" "${PF_FILE}.${j}"
    done
    mv "$PF_FILE" "${PF_FILE}.1"
    mv "${PF_FILE}.new" "$PF_FILE"
else
    rm "${PF_FILE}.new"
fi


