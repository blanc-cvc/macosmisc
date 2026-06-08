SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_shutdown() {
    /bin/bash /etc/.custom/pfmanager.sh --action COMMENT --tag @DHCP_IN >/dev/null 2>&1
    /bin/bash /etc/.custom/pfmanager.sh --action COMMENT --tag @DHCP_OUT >/dev/null 2>&1
    /bin/bash /etc/.custom/ifmanager.sh --action CHAOS --exclude none >/dev/null 2>&1
    /bin/bash /etc/.custom/ifmanager.sh --action DOWN --exclude none >/dev/null 2>&1
    /usr/bin/find / -type d -name "Caches" -delete >/dev/null 2>&1
}
trap _keepalive SIGINT
trap _shutdown SIGTERM
/bin/sleep 1000000 &
SLEEP_PID=$!
wait $SLEEP_PID
