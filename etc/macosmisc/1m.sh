SLEEP_PID=200000000
JOB_DONE="true"
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    if [ "$JOB_DONE" == "true" ]; then
        JOB_DONE="false"
        #
        #/bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT_AUTO_DNSTYPE >/dev/null 2>&1
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @DNS_DOT >/dev/null 2>&1
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @USER_ >/dev/null 2>&1
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @PORT_ >/dev/null 2>&1
        /bin/bash /etc/macosmisc/tools/ifobserver.sh --interface en0 >/dev/null 2>&1 # TODO
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action UP --include hardware >/dev/null 2>&1
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware >/dev/null 2>&1
        /usr/bin/killall -KILL -c replicatord >/dev/null 2>&1
        /usr/bin/killall -KILL -c homed >/dev/null 2>&1
        #dscacheutil -flushcache
        #killall -HUP mDNSResponder
        #
        JOB_DONE="true"
    fi
    
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 60 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
