#!/bin/bash

LOG_FILE=""
FS_ACTION=""

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

if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="/dev/null"
fi

if [[ -z "$FS_ACTION" ]]; then
    echo "Usage: $0 --action <action>"
    exit 1
fi


##

echo "$(date +%H:%M:%S) fsmanager: action:$FS_ACTION" >> "$LOG_FILE"

if [ "$FS_ACTION" == "FIXPERMS" ]; then
    /bin/rm -rf /var/root/Library >/dev/null 2>&1
    /bin/chmod 0500 /var/root >/dev/null 2>&1
    /bin/chmod -R a-s /Users >/dev/null 2>&1
    /bin/chmod -R a-s /Applications >/dev/null 2>&1
    /usr/sbin/chown -R root:wheel /Applications/* >/dev/null 2>&1
    chmod 0640 /etc/pf.* >/dev/null 2>&1
    chmod 0750 /etc/macosmisc/*.sh >/dev/null 2>&1
    chmod 0750 /etc/macosmisc/tools/*.sh >/dev/null 2>&1
    chmod 0644 /etc/macosmisc/logs/*.log >/dev/null 2>&1
    echo "$(date +%H:%M:%S) fsmanager: finding .BAK folders, it’s going to take a while.." >> "$LOG_FILE"
    find / -type d -name ".BAK" -exec chmod 0000 {} \; >/dev/null 2>&1
    find / -type d -name ".BAK" -exec chown root:wheel {} \; >/dev/null 2>&1
    echo "$(date +%H:%M:%S) fsmanager: finding .BAK folders done" >> "$LOG_FILE"
fi

if [ "$FS_ACTION" == "FIXMOUNT" ]; then
    auto_master_file="/etc/auto_master"
    while IFS= read -r line || [[ -n "$line" ]]; do
        read -r col1 col2 col3 rest <<< "$line"
        if [[ "$col1" == "/"* ]] || [[ "$col1" == "#/"* ]]; then
            echo "$col1 $col2 -nobrowse,hidefromfinder,nosuid,nodev,noexec,noauto" >> "$auto_master_file.new"
        else
            echo "$line" >> "$auto_master_file.new"
        fi
    done < "$auto_master_file"
    if [ ! -f "$auto_master_file.bak" ]; then
        mv "$auto_master_file" "$auto_master_file.bak"
    fi
    mv "$auto_master_file.new" "$auto_master_file"
    sed -i '' 's/^AUTOMOUNTD_MNTOPTS=.*/AUTOMOUNTD_MNTOPTS=nosuid,nodev,noexec,noauto/' /etc/autofs.conf
    mount | while IFS= read -r line; do
        if [[ "$line" == /dev/* ]]; then
            DEVICE=$(echo "$line" | awk '{print $1}')
            MOUNT_POINT=$(echo "$line" | awk '{print $3}')
            if [[ "$MOUNT_POINT" == /System/Volumes/* ]]; then
                if [ "$MOUNT_POINT" == "/System/Volumes/Data" ]; then # without noexec
                    /sbin/mount -u -o noauto,nodev,nosuid,noatime,nobrowse -t $FS_TYPE $DEVICE $MOUNT_POINT >> "$LOG_FILE"
                else
                    /sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t $FS_TYPE $DEVICE $MOUNT_POINT >> "$LOG_FILE"
                fi
            elif [[ "$MOUNT_POINT" == /Volumes/* ]]; then # without nobrowse
                /sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime -t $FS_TYPE $DEVICE $MOUNT_POINT >> "$LOG_FILE"
            fi
        fi
    done
fi

if [ "$FS_ACTION" == "LIMITPAM" ]; then
    _utils_prevent_sleep_askforpass
    _utils_pmset # prevent sleep and more
    SOURCE_DIR="/etc/pam.d"
    EXCLUDED_FILES=("authorization" "login" "login.term" "other" "sudo")
    if [ ! -d "$SOURCE_DIR/.BAK" ]; then
        mkdir "$SOURCE_DIR/.BAK"
    fi
    for file in "$SOURCE_DIR"/*; do
        if [ -f "$file" ]; then
            if ! _utils_is_included $(basename "$file") "${EXCLUDED_FILES[@]}"; then
                mv "$file" "$SOURCE_DIR/.BAK/"
            else
                if grep -q "nullok" "$file"; then
                    while IFS= read -r line || [[ -n "$line" ]]; do
                        if [[ "$line" == *"nullok"* ]] && [[ ! "$line" == \#* ]]; then
                            echo "#$line" >> "$file.new"
                            new_line=$(echo "$line" | sed 's/ nullok\([^a-zA-Z0-9_]\)/\1/g; s/ nullok$//')
                            echo "$new_line" >> "$file.new"
                        else
                            echo "$line" >> "$file.new"
                        fi
                    done < "$file"
                    if [ ! -f "$SOURCE_DIR/.BAK/$(basename $file)" ]; then
                        mv "$file" "$SOURCE_DIR/.BAK/"
                    fi
                    mv "$file.new" "$file"
                fi
            fi
        fi
    done
    chmod 0000 "$SOURCE_DIR/.BAK"
    chown root:wheel "$SOURCE_DIR/.BAK"
fi

# move pam files before editing or adding a user
if [ "$FS_ACTION" == "BEFOREEDITNEWUSERPAM" ]; then
    mv "/etc/pam.d/.BAK/chkpasswd" "/etc/pam.d/"
    mv "/etc/pam.d/.BAK/checkpw" "/etc/pam.d/"
    mv "/etc/pam.d/.BAK/passwd" "/etc/pam.d/"
fi

if [ "$FS_ACTION" == "SETUMASK" ]; then
    echo "umask 027" > /etc/launchd.conf
    chmod 0755 /etc/launchd.conf
    chown root:wheel /etc/launchd.conf
    launchctl config user umask 027 >> "$LOG_FILE"
    launchctl config system umask 027 >> "$LOG_FILE"
fi

if [ "$FS_ACTION" == "SETRESOLVER" ]; then
    if [ ! -d /etc/resolver ]; then
        mkdir /etc/resolver
        chmod 0755 /etc/resolver
        chown root:wheel /etc/resolver
    fi
    RESOLVERS=("arpa" "example" "home" "internal" "invalid" "lan" "local" "localhost" "private" "test")
    for resolver_tld in "${RESOLVERS[@]}"; do
        echo "nameserver 127.0.0.1" > "/etc/resolver/$resolver_tld"
    done
    chmod 0644 /etc/resolver/*
    chown root:wheel /etc/resolver/*
fi

if [ "$FS_ACTION" == "PASSWDNOSH" ]; then
    sed -i '' 's|/bin/sh|/usr/bin/false|g' /etc/master.passwd
    sed -i '' 's|/usr/sbin/uucico|/usr/bin/false|g' /etc/master.passwd
    sed -i '' 's|/bin/bash|/usr/bin/false|g' /etc/master.passwd
    sed -i '' 's|/bin/sh|/usr/bin/false|g' /etc/passwd
    sed -i '' 's|/usr/sbin/uucico|/usr/bin/false|g' /etc/passwd
    sed -i '' 's|/bin/bash|/usr/bin/false|g' /etc/passwd
fi

if [ "$FS_ACTION" == "CUPSNONET" ]; then
    sed -i '' '/Listen localhost/ { /^[[:space:]]*#/! s/^/#/; }' /etc/cups/cupsd.conf   
fi
