#!/bin/bash

FILE="/etc/pf.conf"
MAX_ROTATION=9


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

if [[ -z "$PF_TAG" ]] || [[ -z "$PF_ACTION" ]]; then
    echo "Error: Arguments --tag and --action are required."
    echo "Usage: $0 --tag @DENY --action comment"
    exit 1
fi


##

cp "$FILE" "${FILE}.new"

if [ "$PF_ACTION" == "COMMENT" ]; then
    sed -i '' "/^[^#].*${PF_TAG}.*/ s/^/#/" "${FILE}.new"
elif [ "$PF_ACTION" == "UNCOMMENT" ]; then
    sed -i '' "/^#.*${PF_TAG}/ s/^#[[:space:]]*//;" "${FILE}.new"
elif [ "$PF_ACTION" == "ENABLE" ]; then
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.conf >/dev/null 2>&1
elif [ "$PF_ACTION" == "BLOCKALL" ]; then
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.blockall.conf >/dev/null 2>&1
else
    exit 1
fi

if ! pfctl -nf "${FILE}.new" 2>/dev/null; then
    echo "ERROR: Invalid new pf.conf ! Abort."
    rm "${FILE}.new"
    exit 1
fi

HASH_CURRENT=$(md5 -q "$FILE" 2>/dev/null || md5sum "$FILE" | cut -d' ' -f1)
HASH_NEW=$(md5 -q "${FILE}.new" 2>/dev/null || md5sum "${FILE}.new" | cut -d' ' -f1)
if [ "$HASH_CURRENT" != "$HASH_NEW" ]; then
    for (( i=MAX_ROTATION-1; i>=1; i-- )); do
        j=$((i+1))
        [ -f "${FILE}.${i}" ] && mv "${FILE}.${i}" "${FILE}.${j}"
    done
    mv "$FILE" "${FILE}.1"
    mv "${FILE}.new" "$FILE"
else
    rm "${FILE}.new"
fi


