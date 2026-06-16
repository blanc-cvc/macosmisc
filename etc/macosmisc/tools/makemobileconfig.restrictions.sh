#!/bin/bash


MOBILECONFIG=$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>safariAllowed</key><false/>
            <key>allowSiri</key><false/>
            <key>allowAssistant</key><false/>
            <key>allowAirDrop</key><false/>
            <key>allowAirPrint</key><false/>
            <key>allowAppleWatchPairing</key><false/>
            <key>allowBookstore</key><false/>
            <key>allowiTunesStore</key><false/>
            <key>allowNews</key><false/>
            <key>allowGameCenter</key><false/>
            <key>allowMultiplayerGaming</key><false/>
            <key>allowVoiceDialing</key><false/>
            <key>allowAssistantWhileLocked</key><false/>
            <key>allowAppClips</key><false/>
            <key>allowLiveSpeech</key><false/>
            <key>allowCloudBackup</key><false/>
            <key>allowCloudDocumentSync</key><false/>
            <key>allowCloudDesktopAndDocuments</key><false/>
            <key>allowCloudKeychainSync</key><false/>
            <key>allowCloudPhotoLibrary</key><false/>
            <key>allowCloudMail</key><false/>
            <key>allowCloudCalendar</key><false/>
            <key>allowCloudAddressBook</key><false/>
            <key>allowCloudNotes</key><false/>
            <key>allowCloudReminders</key><false/>
            <key>allowPhotoStream</key><false/>
            <key>allowManagedAppsCloudSync</key><false/>
            <key>allowAddingAccounts</key><false/>
            <key>allowAccountModification</key><false/>
            <key>allowBluetoothModification</key><false/>
            <key>allowWiFiPowerOn</key><false/>
            <key>allowHostPairing</key><false/>
            <key>allowUSBRestrictedMode</key><true/>
            <key>allowUntrustedTLSPrompt</key><false/>
            <key>allowAssistiveTouch</key><false/>
            <key>allowSpeakSelection</key><false/>
            <key>allowInvertColors</key><false/>
            <key>allowClassicAccessibility</key><false/>
            <key>allowReducedMotion</key><false/>
            <key>safariAcceptCookies</key><integer>0</integer>
            <key>allowSafariAutoFill</key><false/>

            <key>PayloadDisplayName</key>
            <string>Restrictions Settings</string>
            <key>PayloadIdentifier</key>
            <string>macosmisc.restrictions.settings</string>
            <key>PayloadType</key>
            <string>com.apple.applicationaccess</string>
            <key>PayloadUUID</key>
            <string>$(uuidgen)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
    </array>
    <key>PayloadDisplayName</key>
    <string>Restrictions Profile</string>
    <key>PayloadIdentifier</key>
    <string>macosmisc.restrictions.profile</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadUUID</key>
    <string>$(uuidgen)</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOF
)

FILERESTRICTIONS="$HOME/Downloads/restrictions.mobileconfig"
echo "$MOBILECONFIG" > "$FILERESTRICTIONS"
echo "New mobileconfig: $FILERESTRICTIONS"
