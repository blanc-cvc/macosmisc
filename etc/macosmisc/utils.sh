
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