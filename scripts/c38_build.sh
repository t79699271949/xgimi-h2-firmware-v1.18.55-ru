#!/bin/bash
# C38 = C37 + Aerial 2.20 с языком геокодера ru в restore-apps
set -e
W=/mnt/c/_Hermes_agent_data/fw/work
D=/mnt/c/_Hermes_agent_data
IMG=$W/sys_c38.img
cp $W/sys_c37.img $IMG
echo "старт: $(stat -c %s $IMG)"

echo "=== старый Aerial в образе ==="
debugfs -R "stat /etc/restore-apps/app.orchard.tv.apk" $IMG 2>/dev/null | grep -o "Size: [0-9]*" | head -1
debugfs -w -R "dump /etc/restore-apps/app.orchard.tv.apk /tmp/aerial_old.apk" $IMG >/dev/null 2>&1
echo -n "  sha256 старого: "; sha256sum /tmp/aerial_old.apk | cut -d' ' -f1

echo "=== ставим новый ==="
debugfs -w -R "rm /etc/restore-apps/app.orchard.tv.apk" $IMG >/dev/null
debugfs -w -R "write $D/aerial220_ru2.apk /etc/restore-apps/app.orchard.tv.apk" $IMG >/dev/null
debugfs -w -R "sif /etc/restore-apps/app.orchard.tv.apk mode 0100644" $IMG >/dev/null 2>&1
debugfs -w -R "sif /etc/restore-apps/app.orchard.tv.apk uid 0" $IMG >/dev/null 2>&1
debugfs -w -R "sif /etc/restore-apps/app.orchard.tv.apk gid 0" $IMG >/dev/null 2>&1
debugfs -R "dump /etc/restore-apps/app.orchard.tv.apk /tmp/aerial_new.apk" $IMG >/dev/null 2>&1
echo -n "  sha256 нового:  "; sha256sum /tmp/aerial_new.apk | cut -d' ' -f1
echo -n "  sha256 файла:   "; sha256sum $D/aerial220_ru2.apk | cut -d' ' -f1

echo -n "оверлеев: "; debugfs -R "ls /vendor/overlay" $IMG 2>/dev/null | tr -s ' ' '\n' | grep -c apk
echo -n "restore-apps: "; debugfs -R "ls /etc/restore-apps" $IMG 2>/dev/null | tr -s ' ' '\n' | grep -c apk
echo -n "свободно: "; debugfs -R "stats" $IMG 2>/dev/null | grep "Free blocks" | tr -s ' ' | cut -d' ' -f3
echo "размер: $(stat -c %s $IMG)"
