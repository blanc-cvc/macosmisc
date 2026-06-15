#!/bin/bash

LOG_FILE=""
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

PF_TAG=()
PF_ACTION=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --log)
            LOG_FILE="$2"
            if [ "$LOG_FILE" != "/dev/null" ]; then
                LOG_FILE="$SCRIPT_DIR/../logs/$LOG_FILE.log"
            fi
            shift 2 ;;
        --tag)
            PF_TAG="$2"
            IFS=',' read -ra PF_TAG <<< "$PF_TAG"
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

if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="/dev/null"
fi

if [ "$PF_ACTION" != "BLOCKALL" ] && [ "$PF_ACTION" != "DISABLEALF" ] && [ "$PF_ACTION" != "ENABLE" ]; then
    if [ "$PF_ACTION" == "INITRULES" ] || [ "$PF_ACTION" == "REMOVE" ]; then
        touch "$SCRIPT_DIR/../../pf.conf.lock.priority"
    fi
    if [ ! -f "$SCRIPT_DIR/../../pf.conf.lock" ]; then
        touch "$SCRIPT_DIR/../../pf.conf.lock"
    else
        if [ "$PF_ACTION" != "INITRULES" ] && [ "$PF_ACTION" != "REMOVE" ]; then
            echo "$(date +%H:%M:%S) pfmanager: file is already taken, can't execute --action $PF_ACTION --tag ${PF_TAG[@]}" >> "$LOG_FILE"
            exit 0
        fi
    fi
fi

if [ "$PF_ACTION" == "COMMENT" ] || [ "$PF_ACTION" == "UNCOMMENT" ]; then
    if [[ -z "$PF_TAG" ]] || [[ -z "$PF_ACTION" ]]; then
        echo "Error: Arguments --tag and --action are required."
        echo "Usage: $0 --tag @DENY --action comment"
        exit 1
    fi
fi


##

check_line_has_all_tags() {
    local line="$1"
    shift
    local tags=("$@")
    for tag in "${tags[@]}"; do
        if [[ "$line" != *"$tag"* ]]; then
            return 1
        fi
    done
    return 0
}


##

cp "$PF_FILE" "${PF_FILE}.new"

comment() {
    if [[ ${#PF_TAG[@]} -eq 1 ]]; then
        sed -i '' "/^[^#].*${PF_TAG}.*/ s/^/#/" "${PF_FILE}.new"
    else
        rm "${PF_FILE}.new"
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [ -f "$SCRIPT_DIR/../../pf.conf.lock.priority" ]; then
                exit 0 # keep .new ; going to be overwritten
            fi
            if check_line_has_all_tags "$line" "${PF_TAG[@]}"; then
                if [[ ! "$line" =~ ^# ]]; then
                    echo "#$line" >> "${PF_FILE}.new"
                fi
            else
                echo "$line" >> "${PF_FILE}.new"
            fi
        done < "${PF_FILE}"
    fi
}
uncomment() {
    if [[ ${#PF_TAG[@]} -eq 1 ]]; then
        sed -i '' "/^#.*${PF_TAG}.*/ { /\$extif/! s/^#[[:space:]]*//; }" "${PF_FILE}.new"
    else
        rm "${PF_FILE}.new"
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [ -f "$SCRIPT_DIR/../../pf.conf.lock.priority" ]; then
                exit 0 # keep .new ; going to be overwritten
            fi
            if check_line_has_all_tags "$line" "${PF_TAG[@]}"; then
                if [[ "$line" =~ ^# ]]; then
                    echo "${line#\#}" >> "${PF_FILE}.new"
                fi
            else
                echo "$line" >> "${PF_FILE}.new"
            fi
        done < "${PF_FILE}"
    fi
}
remove() {
    sed -i '' "/${PF_TAG}.*/ { /\$extif/! d; }" "${PF_FILE}.new"
}


if [ "$PF_ACTION" == "COMMENT" ]; then
    echo "$(date +%H:%M:%S) pfmanager: COMMENT ${PF_TAG[@]}" >> "$LOG_FILE"
    comment
elif [ "$PF_ACTION" == "UNCOMMENT" ]; then
    echo "$(date +%H:%M:%S) pfmanager: UNCOMMENT ${PF_TAG[@]}" >> "$LOG_FILE"
    uncomment
elif [ "$PF_ACTION" == "REMOVE" ]; then
    # priority
    echo "$(date +%H:%M:%S) pfmanager: REMOVE ${PF_TAG[@]}" >> "$LOG_FILE"
    remove
elif [ "$PF_ACTION" == "DISABLEALF" ]; then
    echo "$(date +%H:%M:%S) pfmanager: DISABLEALF" >> "$LOG_FILE"
    /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off >/dev/null 2>&1
elif [ "$PF_ACTION" == "ENABLE" ]; then
    echo "$(date +%H:%M:%S) pfmanager: ENABLE" >> "$LOG_FILE"
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.conf >/dev/null 2>&1
elif [ "$PF_ACTION" == "BLOCKALL" ]; then
    echo "$(date +%H:%M:%S) pfmanager: BLOCKALL" >> "$LOG_FILE"
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.blockall.conf >/dev/null 2>&1
elif [ "$PF_ACTION" == "INITRULES" ]; then
    # priority
    echo "$(date +%H:%M:%S) pfmanager: INITRULES" >> "$LOG_FILE"
    IFS_INCLUDED=""
    _utils_wifi_ethernet_interfaces "IFS_INCLUDED"
    _utils_pf_init_rules "${IFS_INCLUDED[@]}"
    echo "$(date +%H:%M:%S) pfmanager: INITRULES ${IFS_INCLUDED[@]} done" >> "$LOG_FILE"
elif [ "$PF_ACTION" == "UNCOMMENT_AUTO_DNSTYPE" ]; then
    echo "$(date +%H:%M:%S) pfmanager: UNCOMMENT_AUTO_DNSTYPE" >> "$LOG_FILE"
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


if [[ "$PF_ACTION" == "REMOVE" || "$PF_ACTION" == "INITRULES" ]] || [ ! -f "$SCRIPT_DIR/../../pf.conf.lock.priority" ]; then
    if ! pfctl -nf "${PF_FILE}.new" 2>/dev/null; then
        mv "${PF_FILE}.new" "${PF_FILE}.invalid"
        cp "${PF_FILE}.1" "${PF_FILE}"
        echo "$(date +%H:%M:%S) pfmanager: INVALID pf.conf.invalid" >> "$LOG_FILE"
        rm "$SCRIPT_DIR/../../pf.conf.lock"*
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
        echo "$(date +%H:%M:%S) pfmanager: new pf.conf from --action $PF_ACTION --tag ${PF_TAG[@]}" >> "$LOG_FILE"
    else
        rm "${PF_FILE}.new"
    fi

    rm "$SCRIPT_DIR/../../pf.conf.lock"*
else
    echo "$(date +%H:%M:%S) pfmanager: priority call, aborting --action $PF_ACTION --tag ${PF_TAG[@]}" >> "$LOG_FILE"
fi