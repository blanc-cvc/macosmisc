
# param1: "key" ; param2: "key1 key2 key3 key4"
# usage: "$KEY" "${TABLE[@]}"
_utils_is_included() {
    local target="$1"
    shift
    local list=("$@")
    for item in "${list[@]}"; do
        if [[ "$item" == "$target" ]]; then
            return 0
        fi
    done
    return 1
}

_utils_generate_random_int() {
    local min=${1:-100}
    local max=${2:-800}
    echo $(( RANDOM % (max - min + 1) + min ))
}

_utils_generate_random_mac() {
    local mac=$(od -An -N6 -tx1 /dev/urandom | tr -d ' \n')
    local first_byte=${mac:0:2}
    local first_char=${first_byte:0:1}
    local dec=$((16#$first_char))
    dec=$(( (dec | 2) & ~1 ))
    local new_first_char=$(printf '%x' $dec)
    mac="${new_first_char}${first_byte:1:1}:${mac:2:2}:${mac:4:2}:${mac:6:2}:${mac:8:2}:${mac:10:2}"
    echo "$mac" | awk '{print toupper($0)}'
}

_utils_generate_random_private_ip() {
    local type=$((RANDOM % 3))
    case $type in
        0) echo "10.$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))" ;;
        1) echo "172.$((16 + RANDOM % 16)).$((RANDOM % 256)).$((RANDOM % 256))" ;;
        2) echo "192.168.$((RANDOM % 256)).$((RANDOM % 256))" ;;
    esac
}

_utils_generate_random_netmask() {
    local cidr=$((RANDOM % 30 + 1))
    local mask=""
    local full_octets=$((cidr / 8))
    local remainder=$((cidr % 8))
    for i in {1..4}; do
        if [ $i -le $full_octets ]; then
            mask+="255"
        elif [ $i -eq $((full_octets + 1)) ]; then
            local val=$(( 256 - (1 << (8 - remainder)) ))
            mask+="$val"
        else
            mask+="0"
        fi
        if [ $i -lt 4 ]; then mask+="."; fi
    done
    echo "$mask"
}

#
## ! GLOBAL VARS: IFS_EXCLUDED IFS_INCLUDED
# param1: "<IFS_EXCLUDED||IFS_INCLUDED>" ; param2: (optional) "<wifi||ethernet>"
_utils_wifi_ethernet_interfaces() {
    local type1="Wi-Fi"
    local type2="Ethernet"
    [ "$2" != "" ] && [ "$2" == "wifi" ] && type2="Wi-Fi"
    [ "$2" != "" ] && [ "$2" == "ethernet" ] && type1="Ethernet"
    local netifaces=($(ifconfig -v | awk -v type1="$type1" -v type2="$type2" '
    /^[a-z0-9]+:/ { 
        gsub(/:$/, "", $1); iface=$1; next 
    }
    /type:/ && ($2 == type1 || $2 == type2) && iface !~ /^(awdl|llw)/ { 
        print iface 
    }'))
    [ "$1" == "IFS_EXCLUDED" ] && IFS_EXCLUDED=(${netifaces[@]})
    [ "$1" == "IFS_INCLUDED" ] && IFS_INCLUDED=(${netifaces[@]})
}



_utils_pf_init_rules() {
    local interface_list=("$@")
    local tmp_file=$(mktemp)
    local PF_FILE=""

    if [[ "$(id -u)" == "0" ]]; then
        PF_FILE="/etc/pf.conf"
    else
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PF_FILE="$SCRIPT_DIR/../../pf.conf.test"
    fi

    for interface in "${interface_list[@]}"; do
        cp "$PF_FILE" "$tmp_file"
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *'$extif'* ]]; then
                new_line="${line//\$extif/$interface} # @IF_$interface"
                if ! grep -qF "$new_line" "$tmp_file" && ! grep -qF "${new_line%% #*}" "$tmp_file"; then
                    awk -v orig="$line" -v insert="$new_line" '
                    {
                        print $0
                        if ($0 == orig) print insert
                    }' "$tmp_file" > "${tmp_file}.new" && mv "${tmp_file}.new" "$tmp_file"
                fi
            fi
        done < "$PF_FILE"

        mv "$tmp_file" "${PF_FILE}.new"
    done
}

# doesnt really works
_utils_detect_dns_type() {
    local r1=$(printf "%04d" $((RANDOM % 1000000)))
    local r2=$(printf "%04d" $((RANDOM % 1000000)))
    local r3=$(printf "%04d" $((RANDOM % 1000000)))
    local random_tld="${r1}${r2}${r3}"
    local fake_domain="macosmisc.${random_tld}"
    dns-sd -G v4 "$fake_domain" >/dev/null 2>&1 &
    PID=$!
    sleep 5
    kill $PID >/dev/null 2>&1
    wait $PID >/dev/null 2>&1
    sleep 5
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

_utils_pmset() {
    PMSET0=("displaysleep" "disksleep" "sleep" "womp" "ring" "lidwake" "acwake" "proximitywake" "powernap" "lessbright" "halfdim" "standby" "autopoweroff" "networkoversleep" "autorestart" "ttyskeepawake")
    PMSET1=("sms" "destroyfvkeyonstandby" "disablesleep")
    for pm in "${PMSET0[@]}"; do
        pmset -a "$pm" 0 >/dev/null 2>&1
    done
    for pm in "${PMSET0[@]}"; do
        pmset -a "$pm" 1 >/dev/null 2>&1
    done
    pmset -a hibernatemode 25 >/dev/null 2>&1
}

_utils_prevent_sleep_askforpass() {
    defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime -int 0 >/dev/null 2>&1
    for user_dir in /Users/*; do
        username=$(basename "$user_dir")
        if [ "$username" != "Shared" ] && [ "$username" != "Guest" ] && [[ $username != .* ]]; then
            uid=$(id -u "$username" 2>/dev/null)
            if [[ -n "$uid" ]]; then
                sudo -u "$username" defaults -currentHost write com.apple.screensaver idleTime -int 0 >/dev/null 2>&1
                sudo -u "$username" defaults -currentHost write com.apple.screensaver askForPassword -int 0 >/dev/null 2>&1
                sudo -u "$username" defaults -currentHost write com.apple.loginwindow askForPassword -int 0 >/dev/null 2>&1
                sudo -u "$username" defaults write com.apple.screensaver askForPassword -int 0 >/dev/null 2>&1
                sudo -u "$username" defaults write com.apple.loginwindow askForPassword -int 0 >/dev/null 2>&1
                killall -u "$username" cfprefsd >/dev/null 2>&1
            fi
        fi
    done
}
