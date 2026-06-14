#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/Library/LaunchDaemons/"* "/Library/LaunchDaemons/"
chmod 0644 /Library/LaunchDaemons/local*
chown -R root:wheel /Library/LaunchDaemons/local*
cp -r "$SCRIPT_DIR/etc/macosmisc" "/etc/"
chmod -R 0750 /etc/macosmisc
chown -R root:wheel /etc/macosmisc
chmod 0755 /etc/macosmisc
chmod 0755 /etc/macosmisc/tools
if [ ! -f "/etc/pf.conf.original" ]; then
    mv /etc/pf.conf /etc/pf.conf.original
fi
if [ ! -f "/etc/pf.os.original" ]; then
    mv /etc/pf.os /etc/pf.os.original
fi
cp "$SCRIPT_DIR/etc/pf.conf" "/etc/"
cp "$SCRIPT_DIR/etc/pf.blockall.conf" "/etc/"
touch /etc/pf.os
chmod 0750 /etc/pf.*
chown root:wheel /etc/pf.*

for file in "$SCRIPT_DIR/Library/LaunchDaemons/"*; do
    if [ -f "$file" ]; then
        launchctl unload -w "/Library/LaunchDaemons/$(basename $file)" >/dev/null 2>&1
        launchctl load -w "/Library/LaunchDaemons/$(basename $file)"
    fi
done

echo "EXEC: /etc/macosmisc/once.sh"
/bin/bash /etc/macosmisc/once.sh

/bin/bash /etc/macosmisc/tools/makemobileconfig.sh
