SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    /bin/bash /etc/macosmisc/tools/pfmanager.sh --action ENABLE >/dev/null 2>&1
    /bin/bash /etc/macosmisc/tools/ifmanager.sh --action AIRPORTPREFS --include wifi >/dev/null 2>&1
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 10 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
