SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_shutdown() {
    if [ ! -f "/etc/macosmisc/off.install.lock" ]; then
        for log in "off" "1s" "2s" "10s" "1m" "1h" "1d" "once"; do
            echo "" > "/etc/macosmisc/logs/$log.log"
        done
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action REMOVE --tag @IF_ --log off
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action BLOCKALL --log off
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude none --log off
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action DOWN --exclude none --log off
        /bin/bash /etc/macosmisc/tools/fsmanager.sh --action SETUMASK --log off
        /usr/bin/find / -type d -name "Caches" -delete >/dev/null 2>&1
    fi
}
trap _keepalive SIGINT
trap _shutdown SIGTERM
/bin/sleep 1000000 &
SLEEP_PID=$!
wait $SLEEP_PID
