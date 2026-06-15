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
        for log in "1s" "2s" "10s"; do
            echo "" > "/etc/macosmisc/logs/$log.log"
        done
        #/bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT_AUTO_DNSTYPE --log 1m
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @DNS_DOT --log 1m
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @USER_ --log 1m
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action UNCOMMENT --tag @PORT_ --log 1m
        /bin/bash /etc/macosmisc/tools/ifobserver.sh --action WATCHDHCP --interface hardware --log 1m
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action UP --include hardware --log 1m
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware --log 1m
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
