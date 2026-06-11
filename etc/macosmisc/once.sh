/bin/bash /etc/macosmisc/tools/pfmanager.sh --action ENABLE >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action RANDOM_MAC --include hardware >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action DOWN --exclude none >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/pfmanager.sh --action INITRULES >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s4 /System/Volumes/VM >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s2 /System/Volumes/Preboot >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime,nobrowse -t apfs /dev/disk1s6 /System/Volumes/Update >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noatime,nobrowse -t apfs /dev/disk1s1 /System/Volumes/Data >/dev/null 2>&1
/sbin/mount -u -o noauto,nodev,nosuid,noexec,noatime -t apfs /dev/disk2s1 /Volumes/Disk2 >/dev/null 2>&1
exit 0