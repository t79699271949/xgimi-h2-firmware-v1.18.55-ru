#!/bin/bash
set -e
W=/mnt/c/_Hermes_agent_data/fw/work
D=/mnt/c/_Hermes_agent_data
IMG=$W/sys_c34.img
cp $W/sys_c33.img $IMG
echo "старт: $(stat -c %s $IMG) ($(( $(stat -c %s $IMG)/4096 )) блоков)"
echo "=== старый хук:"
debugfs -R "stat /bin/install-recovery.sh" $IMG 2>/dev/null | grep -E "Size"
debugfs -w -R "rm /bin/install-recovery.sh" $IMG >/dev/null 2>&1 || true
debugfs -w -R "write $D/agent/install-recovery-c34.sh /bin/install-recovery.sh" $IMG
debugfs -w -R "sif /bin/install-recovery.sh mode 0100755" $IMG >/dev/null 2>&1
debugfs -w -R "sif /bin/install-recovery.sh uid 0" $IMG >/dev/null 2>&1
debugfs -w -R "sif /bin/install-recovery.sh gid 0" $IMG >/dev/null 2>&1
echo "=== новый хук:"
debugfs -R "stat /bin/install-recovery.sh" $IMG 2>/dev/null | grep -E "Size|Mode"
echo "=== overlay:"; debugfs -R "ls /vendor/overlay" $IMG 2>/dev/null | tr -s ' ' '\n' | grep -c apk
echo "=== restore-apps:"; debugfs -R "ls /etc/restore-apps" $IMG 2>/dev/null | tr -s ' ' '\n' | grep -c apk
echo "=== анимации:"; debugfs -R "ls -l /media" $IMG 2>/dev/null | grep animation | awk '{print $5, $NF}'
echo "итог: $(stat -c %s $IMG) ($(( $(stat -c %s $IMG)/4096 )) блоков)"
