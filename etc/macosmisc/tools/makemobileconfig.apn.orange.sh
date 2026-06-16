#!/bin/bash

MOBILECONFIG=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>AttachAPN</key>
            <dict>
                <key>Name</key><string>orange</string>
                <key>AuthenticationType</key><string>PAP</string>
                <key>Username</key><string>orange</string>
                <key>Password</key><string>orange</string>
                <key>APNProtocol</key><string>IPv6</string><!-- IPv4 -->
            </dict>
            <key>APNs</key>
            <array>
                <dict>
                    <key>Name</key><string>orange</string>
                    <key>AuthenticationType</key><string>PAP</string>
                    <key>Username</key><string>orange</string>
                    <key>Password</key><string>orange</string>
                    <key>APNProtocol</key><string>IPv6</string><!-- IPv4 -->
                </dict>
            </array>
            <key>TetheringAPN</key>
            <dict>
                <key>Name</key><string>orange</string>
                <key>AuthenticationType</key><string>CHAP</string>
                <key>Username</key><string>false</string>
                <key>Password</key><string>false</string>
                <key>APNProtocol</key><string>IPv4</string>
            </dict>
            <key>MMS</key>
            <dict>
                <key>Name</key><string>orange.acte</string>
                <key>AuthenticationType</key><string>CHAP</string>
                <key>Username</key><string>false</string>
                <key>Password</key><string>false</string>
                <key>MMSC</key><string>https://apple.com</string>
                <key>MMSProxyServer</key><string>apple.com</string>
                <key>MMSProxyPort</key><integer>443</integer>
                <key>MaximumMMSMessageSize</key><integer>1</integer>
                <key>MMSUserAgentProfileURL</key><string>https://apple.com/schemas/uaprof.rdf</string>
            </dict>
            <key>PayloadDisplayName</key>
            <string>APN Orange Settings</string>
            <key>PayloadIdentifier</key>
            <string>macosmisc.orange.apn.settings</string>
            <key>PayloadType</key>
            <string>com.apple.cellular</string>
            <key>PayloadUUID</key>
            <string>$(uuidgen)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDisplayName</key>
    <string>APN Orange Profile</string>
    <key>PayloadIdentifier</key>
    <string>macosmisc.orange.apn.profile</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadScope</key>
    <string>System</string>
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

FILEAPN="$HOME/Downloads/orange.apn.mobileconfig"
echo "$MOBILECONFIG" > "$FILEAPN"
echo "New mobileconfig: $FILEAPN"
