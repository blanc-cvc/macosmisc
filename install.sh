#!/bin/bash

touch /etc/pf.conf.lock
touch /etc/macosmisc/off.install.lock

launchctl list | grep macosmisc | while IFS= read -r result; do
    pid=$(echo "$result" | awk '{print $1}')
    label=$(echo "$result" | awk '{print $3}')
    echo "Unloading /Library/LaunchDaemons/$label.plist and killing pid: $pid"
    launchctl unload -w /Library/LaunchDaemons/"$label".plist 2>/dev/null
    if [[ "$pid" =~ ^[0-9]+$ ]]; then
        kill -9 "$pid" 2>/dev/null
    fi
done
echo "Killing all sleep ps.."
killall -9 sleep 2>/dev/null
rm /etc/macosmisc/off.install.lock

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing files.."
cp "$SCRIPT_DIR/Library/LaunchDaemons/"* "/Library/LaunchDaemons/"
chmod 0644 /Library/LaunchDaemons/local*
chown -R root:wheel /Library/LaunchDaemons/local*
cp -r "$SCRIPT_DIR/etc/macosmisc" "/etc/"
chmod -R 0750 /etc/macosmisc
chown -R root:wheel /etc/macosmisc
chmod 0755 /etc/macosmisc
chmod 0755 /etc/macosmisc/tools
chmod 0755 /etc/macosmisc/logs
for log in "off" "1s" "2s" "10s" "1m" "1h" "1d" "once"; do
    echo "" > "/etc/macosmisc/logs/$log.log"
done
chmod 0644 /etc/macosmisc/logs/*.log
if [ ! -f "/etc/pf.conf.original" ]; then
    mv /etc/pf.conf /etc/pf.conf.original
fi
if [ ! -f "/etc/pf.os.original" ]; then
    mv /etc/pf.os /etc/pf.os.original
fi
cp "$SCRIPT_DIR/etc/pf.conf" "/etc/"
cp "$SCRIPT_DIR/etc/pf.blockall.conf" "/etc/"
touch /etc/pf.os
chmod 0640 /etc/pf.*
chown root:wheel /etc/pf.*

for file in "$SCRIPT_DIR/Library/LaunchDaemons/"*; do
    if [ -f "$file" ]; then
        echo "Loading /Library/LaunchDaemons/$(basename $file)"
        launchctl load -w "/Library/LaunchDaemons/$(basename $file)"
    fi
done

#echo "EXEC: /etc/macosmisc/once.sh"
#/bin/bash /etc/macosmisc/once.sh

/bin/bash /etc/macosmisc/tools/makemobileconfig.sh

echo "#"
echo "check /etc/macosmisc/logs/once.log for details"
echo "      and others in /etc/macosmisc/logs/"
