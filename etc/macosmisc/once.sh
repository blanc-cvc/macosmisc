touch /etc/pf.conf.lock # to facilitate INITRULES
/bin/bash /etc/macosmisc/tools/pfmanager.sh --action ENABLE --log once
/bin/bash /etc/macosmisc/tools/pfmanager.sh --action DISABLEALF --log once
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action RANDOM_MAC --include hardware --log once
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action DOWN --exclude none --log once
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware --log once
/bin/bash /etc/macosmisc/tools/pfmanager.sh --action INITRULES --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXMOUNT --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action LIMITPAM --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action SETUMASK --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action SETRESOLVER --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action PASSWDNOSH --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action CUPSNONET --log once
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXPERMS --log once
exit 0