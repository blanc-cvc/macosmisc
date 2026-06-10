SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    dscacheutil -flushcache
    killall -HUP mDNSResponder
    /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT_AUTO_DNSTYPE >/dev/null 2>&1
    /bin/bash /etc/macosmisc/tools/ifobserver.sh --interface en0 >/dev/null 2>&1
    /bin/bash /etc/macosmisc/tools/ifmanager.sh --action UP --include hardware >/dev/null 2>&1
    /bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware >/dev/null 2>&1
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
