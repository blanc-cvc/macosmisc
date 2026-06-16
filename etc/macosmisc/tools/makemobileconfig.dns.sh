#!/bin/bash

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --action)
            TYPE="$2"
            TYPE=$(echo "$FS_ACTION" | awk '{print toupper($0)}')
            shift 2 ;;
        *)
            echo "Error: Unknown option : $1"
            echo "Usage: $0 --action <action>"
            exit 1 ;;
    esac
done

MOBILECONFIG=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>DNSSettings</key>
            <dict>
                <key>DNSProtocol</key>
                <string>HTTPS</string>
                <key>ServerURL</key>
                <string>https://unicast.censurfridns.dk/dns-query</string>
                <key>ServerAddresses</key>
                <array>
                    <string>2a01:3a0:53:53::</string>
                    <string>89.233.43.71</string>
                </array>
                <key>ServerName</key>
                <string>unicast.censurfridns.dk</string>
            </dict>
            <key>PayloadDisplayName</key>
            <string>DoH censurfridns Settings</string>
            <key>PayloadType</key>
            <string>com.apple.dnsSettings.managed</string>
            <key>PayloadIdentifier</key>
            <string>dk.censurfridns.doh.settings</string>
            <key>PayloadUUID</key>
            <string>00000000-0000-0000-0000-000000000000</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDisplayName</key>
    <string>DoH censurfridns Profile</string>
    <key>PayloadIdentifier</key>
    <string>dk.censurfridns.doh.profile</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadScope</key>
    <string>User</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>$(uuidgen)</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOF
)

DNSPayloadUUID=""

makedoh() {
    FILEDOH="$HOME/Downloads/doh.censurfridns.mobileconfig"
    DNSPayloadUUID=$(uuidgen)
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed "s/00000000-0000-0000-0000-000000000000/$DNSPayloadUUID/g")
    echo "$MOBILECONFIG" > "$FILEDOH"
    echo "New mobileconfig: $FILEDOH"
}

makedot() {
    FILEDOT="$HOME/Downloads/dot.censurfridns.mobileconfig"
    if [ ! -z "$DNSPayloadUUID" ]; then
        MOBILECONFIG=$(echo "$MOBILECONFIG" | sed "s/$DNSPayloadUUID/00000000-0000-0000-0000-000000000000/g")
    fi
    DNSPayloadUUID=$(uuidgen)
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed "s/00000000-0000-0000-0000-000000000000/$DNSPayloadUUID/g")
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed '/ServerURL/d')
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed '/dns-query/d')
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed 's/doh/dot/g')
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed 's/DoH/DoT/g')
    MOBILECONFIG=$(echo "$MOBILECONFIG" | sed 's/HTTPS/TLS/g')
    echo "$MOBILECONFIG" > "$FILEDOT"
    echo "New mobileconfig: $FILEDOT"
    sed -i '' "s|00000000-0000-0000-0000-000000000000|$DNSPayloadUUID|g" "$HOME/Downloads/ios.builtinfilter.mobileconfig"
}

if [ "$TYPE" == "DOH" ]; then
    makedoh
elif [ "$TYPE" == "DOT" ]; then
    makedot
else
    makedoh
    makedot
fi
