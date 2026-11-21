#!/bin/bash
set -e
W=/mnt/c/_Hermes_agent_data/fw/work
D=/mnt/c/_Hermes_agent_data
IMG=$W/sys_c33.img
cp $W/sys_c32.img $IMG
echo "старт: $(stat -c %s $IMG) ($(( $(stat -c %s $IMG)/4096 )) блоков)"

add() {
  local src=$1 dst=$2
  debugfs -w -R "write $src $dst" $IMG >/dev/null 2>&1
  debugfs -w -R "sif $dst mode 0100644" $IMG >/dev/null 2>&1
  debugfs -w -R "sif $dst uid 0" $IMG >/dev/null 2>&1
  debugfs -w -R "sif $dst gid 0" $IMG >/dev/null 2>&1
}
add $D/overlay_config_signed.apk /vendor/overlay/ru-config.apk
add $D/overlay_soundermode_signed.apk /vendor/overlay/ru-soundermode.apk
add $D/overlay_bluetooth_signed.apk /vendor/overlay/ru-bluetooth.apk

echo "=== overlay (должно быть 12):"
debugfs -R "ls /vendor/overlay" $IMG 2>/dev/null | tr -s ' ' '\n' | grep apk | sort
echo "=== анимации:"
debugfs -R "ls -l /media" $IMG 2>/dev/null | grep animation | awk '{print $5, $NF}'
echo "свободно: $(debugfs -R 'stats' $IMG 2>/dev/null | grep 'Free blocks')"
echo "итог: $(stat -c %s $IMG) ($(( $(stat -c %s $IMG)/4096 )) блоков)"
