/bin/bash /etc/.custom/pfmanager.sh --action COMMENT --tag @DHCP_IN >/dev/null 2>&1
/bin/bash /etc/.custom/pfmanager.sh --action COMMENT --tag @DHCP_OUT >/dev/null 2>&1
/sbin/pfctl -e >/dev/null 2>&1
/sbin/pfctl -f /etc/pf.conf >/dev/null 2>&1
/bin/bash /etc/.custom/ifmanager.sh --action RANDOM_MAC --include en0 >/dev/null 2>&1
/bin/bash /etc/.custom/ifmanager.sh --action DOWN --exclude none >/dev/null 2>&1
/bin/bash /etc/.custom/ifmanager.sh --action CHAOS --exclude en0 >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s4 /System/Volumes/VM >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s2 /System/Volumes/Preboot >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s6 /System/Volumes/Update >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noatime,nobrowse -t apfs /dev/disk1s1 /System/Volumes/Data >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime -t apfs /dev/disk2s1 /Volumes/Disk2 >/dev/null 2>&1
exit 0
