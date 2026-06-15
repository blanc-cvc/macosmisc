SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    echo "" > /etc/macosmisc/logs/1m.log
    /opt/local/bin/port selfupdate >> /etc/macosmisc/logs/1h.log
    /opt/local/bin/port upgrade outdated >> /etc/macosmisc/logs/1h.log
    /bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXMOUNT --log 1h
    /bin/bash /etc/macosmisc/tools/fsmanager.sh --action LIMITPAM --log 1h
    /bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXPERMS --log 1h
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 3600 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
