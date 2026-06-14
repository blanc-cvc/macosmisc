execute install.sh

edit the content of the scripts in /etc/macosmisc/

1s.sh: every second
2s.sh: every 2 seconds
10s.sh: every 10 seconds
1m.sh: every minute
1h.sh: every hour
1d.sh: every day
once.sh: at startup
off.sh: at shutdown

check status: "launchctl list | grep macosmisc"
