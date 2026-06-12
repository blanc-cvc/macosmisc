#!/bin/bash

FS_ACTION=""

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# sourced functions start with _
#source "$SCRIPT_DIR/utils.sh"


while [[ "$#" -gt 0 ]]; do
    case $1 in
        --action)
            FS_ACTION="$2"
            FS_ACTION=$(echo "$FS_ACTION" | awk '{print toupper($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --action <action>"
            exit 1 ;;
    esac
done

if [[ -z "$FS_ACTION" ]]; then
    echo "Usage: $0 --action <action>"
    exit 1
fi


##

if [ "$FS_ACTION" == "FIXPERMS" ]; then
    /bin/rm -rf /var/root/Library >/dev/null 2>&1
    /bin/chmod 0500 /var/root >/dev/null 2>&1
    /bin/chmod -R a-s /Users 
    /bin/chmod -R a-s /Applications
    /usr/sbin/chown -R root:wheel /Applications/*
fi

if [ "$FS_ACTION" == "FIXMOUNT" ]; then
    mount | while IFS= read -r line; do
        if [[ "$line" == /dev/* ]]; then
            DEVICE=$(echo "$line" | awk '{print $1}')
            MOUNT_POINT=$(echo "$line" | awk '{print $3}')
            if [[ "$MOUNT_POINT" == /System/Volumes/* ]]; then
                if [ "$MOUNT_POINT" == "/System/Volumes/Data" ]; then # without noexec
                    /sbin/mount -u -o noauto,nodev,nosuid,noatime,nobrowse -t $FS_TYPE $DEVICE $MOUNT_POINT >/dev/null 2>&1
                else
                    /sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t $FS_TYPE $DEVICE $MOUNT_POINT >/dev/null 2>&1
                fi
            elif [[ "$MOUNT_POINT" == /Volumes/* ]]; then # without nobrowse
                /sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime -t $FS_TYPE $DEVICE $MOUNT_POINT >/dev/null 2>&1
            fi
        fi
    done
fi