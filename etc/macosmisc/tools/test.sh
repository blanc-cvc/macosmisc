#!/bin/bash

detect_doh() {
    dns-sd -G v4 github.com >/dev/null 2>&1 &
    PID=$!
    sleep 5
    kill $PID >/dev/null 2>&1
    wait $PID >/dev/null 2>&1

    sleep 1

    local logs=$(log show --last 20s --predicate 'process == "mDNSResponder" && eventMessage contains "type:"' --style compact 2>/dev/null)

    if echo "$logs" | grep -q "type: DoH"; then
        echo "DoH"
    elif echo "$logs" | grep -q "type: DoT"; then
        echo "DoT"
    elif echo "$logs" | grep -q "type: Do53"; then
        echo "Do53"
    else
        echo "Unknown"
    fi
}
detect_doh

exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PF_FILE="$SCRIPT_DIR/../../pf.conf.test"

interfaces=("en0" "en1")

TEMP_FILE=$(mktemp)

for interface in "${interfaces[@]}"; do
    cp "$PF_FILE" "$TEMP_FILE"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *'$extif'* ]]; then
            new_line=""
            if [[ "$line" == *"@BLOCK_NOT_IF"* ]]; then
                pf_interface_list=$(IFS=', '; echo "${interfaces[*]}")
                pf_interface_list="{ $pf_interface_list }"
                pf_interface_list_comments=""
                for iface in "${interfaces[@]}"; do
                    pf_interface_list_comments="$pf_interface_list_comments # @IF_$iface"
                done
                new_line="${line//\$extif/$pf_interface_list} $pf_interface_list_comments"
            else
                new_line="${line//\$extif/$interface} # @IF_$interface"
            fi
            if ! grep -qF "$new_line" "$TEMP_FILE" && ! grep -qF "${new_line%% #*}" "$TEMP_FILE"; then
                awk -v orig="$line" -v insert="$new_line" '
                {
                    print $0
                    if ($0 == orig) print insert
                }' "$TEMP_FILE" > "${TEMP_FILE}.new" && mv "${TEMP_FILE}.new" "$TEMP_FILE"
            fi
        fi
    done < "$PF_FILE"

    mv "$TEMP_FILE" "$PF_FILE"
done




exit 0





NET_IFACES=($(ifconfig -v | awk '
/^[a-z0-9]+:/ { 
    gsub(/:$/, "", $1); iface=$1; next 
}
/type:/ && ($2 == "Wi-Fi" || $2 == "Ethernet") && iface !~ /^(awdl|llw)/ { 
    print iface 
}'))

echo "${NET_IFACES[@]}"