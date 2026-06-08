SLEEP_PID=200000000
_killsleep() {
    /bin/kill $SLEEP_PID >/dev/null 2>&1
}
_keepalive() {
    _killsleep
    exit 0
}
_job() {
    /sbin/pfctl -e >/dev/null 2>&1
    /sbin/pfctl -f /etc/pf.conf >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs P2PFirewall=YES >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs P2PDevicesManaged=NO >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs DisconnectOnLogout=YES >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs DisableMultiChannelRanging=YES >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs OffloadAutoConfigureSleepScan=YES >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs OffloadAutoConfigureIPAddresses=YES >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs RequireAdminIBSS=YES OffloadSleepScanCycleRestTime=80 >/dev/null 2>&1
    /usr/libexec/airportd en0 prefs OffloadSleepScanCycleRestTime=80 >/dev/null 2>&1
}
trap _keepalive SIGINT SIGTERM
while true; do
    /bin/sleep 10 &
    SLEEP_PID=$!
    wait $SLEEP_PID
    _job
done
