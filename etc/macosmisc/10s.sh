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
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action ENABLE --log 10s
        /bin/bash /etc/macosmisc/tools/pfmanager.sh --action DISABLEALF --log 10s
        /bin/bash /etc/macosmisc/tools/ifmanager.sh --action AIRPORTPREFS --include wifi --log 10s
        #
        JOB_DONE="true"
    fi
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 10 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
