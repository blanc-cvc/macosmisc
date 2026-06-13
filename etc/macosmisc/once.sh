/bin/bash /etc/macosmisc/tools/pfmanager.sh --action ENABLE >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action RANDOM_MAC --include hardware >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action DOWN --exclude none >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/ifmanager.sh --action CHAOS --exclude hardware >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/pfmanager.sh --action INITRULES >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXPERMS >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action FIXMOUNT >/dev/null 2>&1
/bin/bash /etc/macosmisc/tools/fsmanager.sh --action LIMITPAM >/dev/null 2>&1
exit 0