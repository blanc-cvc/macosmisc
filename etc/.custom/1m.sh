SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    /bin/bash /etc/.custom/ifobserver.sh --interface en0 >/dev/null 2>&1
    /bin/bash /etc/.custom/ifmanager.sh --action UP --include en0 >/dev/null 2>&1
    /bin/bash /etc/.custom/ifmanager.sh --action CHAOS --exclude en0 >/dev/null 2>&1
    /bin/chmod -R 0000 /var/root/Library >/dev/null 2>&1
    /bin/chmod 0500 /var/root >/dev/null 2>&1
    /usr/bin/killall -KILL -c replicatord >/dev/null 2>&1
    /usr/bin/killall -KILL -c homed >/dev/null 2>&1
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 60 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
