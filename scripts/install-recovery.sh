#!/system/bin/sh
if [ -f /system/recovery.img ]; then
  applypatch -t /system/recovery.img /dev/block/platform/mstar_mci.0/by-name/recovery
  if [ $? != 0 ]; then
    log -t recovery "Installing new recovery image"
    busybox dd if=/system/recovery.img of=/dev/block/platform/mstar_mci.0/by-name/recovery bs=64k conv=fsync
    log -t recovery "finish installing the new recovery image"
  else
    log -t recovery "Recovery image already installed"
  fi
else
  log -t recovery "Recovery image not exist"
fi

# ============ projector boot hook (C20: надёжный запуск лаунчера) ============
mkdir -p /data/local/agent 2>/dev/null
chmod 777 /data/local/agent 2>/dev/null
LOG=/data/local/agent/boot.log

{
  echo "=== boot $(date)"
  echo "uid: $(id)"
  setprop service.adb.tcp.port 5555
  setprop persist.service.adb.enable 1
  stop adbd 2>/dev/null
  start adbd 2>/dev/null
  sleep 2
  echo "adbd: $(getprop init.svc.adbd)"
} > $LOG 2>&1

# локаль и таймзона
setprop persist.sys.locale ru-RU 2>/dev/null
setprop persist.sys.language ru 2>/dev/null
setprop persist.sys.country RU 2>/dev/null
setprop persist.sys.timezone Europe/Moscow 2>/dev/null

# не гасить экран при подключённом питании (проектор работает как экран)
/system/bin/settings put global stay_on_while_plugged_in 3 2>/dev/null
/system/bin/settings put system screen_off_timeout 1800000 2>/dev/null
# заставка (screensaver) не должна включаться
/system/bin/settings put secure screensaver_enabled 0 2>/dev/null
/system/bin/settings put secure screensaver_components '' 2>/dev/null

# агент мониторинга
if [ -f /system/etc/projector-agent/start.sh ]; then
  nohup /system/bin/sh /system/etc/projector-agent/start.sh >/dev/null 2>&1 &
  echo "agent started" >> $LOG
fi

# ---- домашний экран: ждём готовности PMS, потом переключаем ----
(
  i=0
  while [ $i -lt 48 ]; do
    if /system/bin/pm list packages >/dev/null 2>&1; then break; fi
    sleep 5
    i=$((i+1))
  done
  echo "--- pm ready after $((i*5))s" >> $LOG
  sleep 15

  /system/bin/pm disable-user --user 0 com.xgimi.home >> $LOG 2>&1
  echo "disable home rc=$?" >> $LOG
  sleep 5

  /system/bin/am start -n app.orchard.tv/.MainActivity >> $LOG 2>&1
  echo "am start rc=$?" >> $LOG
  sleep 30

  if /system/bin/dumpsys activity activities 2>/dev/null | grep -q "app.orchard.tv"; then
    echo "AERIAL_OK" >> $LOG
  else
    echo "AERIAL_RETRY" >> $LOG
    /system/bin/am start -n app.orchard.tv/.MainActivity >> $LOG 2>&1
    sleep 20
    if /system/bin/dumpsys activity activities 2>/dev/null | grep -q "app.orchard.tv"; then
      echo "AERIAL_OK_2" >> $LOG
    else
      /system/bin/pm enable com.xgimi.home >> $LOG 2>&1
      /system/bin/am start -a android.intent.action.MAIN -c android.intent.category.HOME >> $LOG 2>&1
      echo "AERIAL_FAIL reverted" >> $LOG
    fi
  fi
) &

# ---- автоочистка от рекламы/телеметрии/китайского контента (обратимо) ----
(
  sleep 90
  echo "--- debloat $(date)" >> $LOG
  for p in \
    com.xgimi.adservice com.xgimi.msgcenter com.xgimi.atmosphere com.xgimi.screensaver \
    com.xgimi.datareporter com.xgimi.appmarket com.xgimi.newappmarket com.xgimi.payview \
    com.xgimi.remote com.xgimi.iot com.xgimi.minitvfactory com.xgimi.instruction30 \
    com.xgimi.burnin com.xgimi.recamera com.xgimi.skinmanager com.xgimi.skinconfig \
    com.loostone.puremic com.android.noisefield com.xgimi.voiceoffline com.xgimi.doubanfm \
    com.xgimi.duertts com.pptv.tvsports com.gitvjimi.video com.kuyun.common.identifer \
    com.jd.smart.tv.sdk com.xgimi.activitypage com.xgimi.htmlpage com.xgimi.manager \
    com.xgimi.transfer com.android.mcast com.android.wallpaper com.xgimi.skin.black \
    com.xgimi.skin.classicblue com.android.htmlviewer com.xgimi.user \
    com.xgimi.wirelessscreen com.xgimi.miracast com.xgimi.account com.xgimi.upgrade \
    com.xgimi.stream.media com.xgimi.streammeadiaplayer ; do
    /system/bin/pm uninstall --user 0 $p >/dev/null 2>&1 && echo "removed $p" >> $LOG
  done
  echo "--- debloat done: $(/system/bin/pm list packages | wc -l) packages" >> $LOG
) &

# ---- восстановление приложений из /system/etc/restore-apps (переживают factory reset) ----
(
  sleep 60
  echo "--- restore-apps $(date)" >> $LOG
  for apk in /system/etc/restore-apps/*.apk; do
    [ -f "$apk" ] || continue
    name=${apk##*/}
    pkg=${name%.apk}
    if /system/bin/pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
      echo "present: $pkg" >> $LOG
    else
      /system/bin/pm install -r "$apk" >> $LOG 2>&1
      echo "installed: $pkg rc=$?" >> $LOG
    fi
  done
  # после установки — назначить клавиатуру, если она есть
  /system/bin/ime enable org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService >/dev/null 2>&1
  /system/bin/ime set org.liskovsoft.androidtv.rukeyboard/com.liskovsoft.leankeyboard.ime.LeanbackImeService >/dev/null 2>&1

  # китайская клавиатура Sogou не нужна: LeanKeyboard назначена вручную
  /system/bin/pm disable-user --user 0 com.sohu.inputmethod.sogou.tv >> $LOG 2>&1
  # голосовой распознаватель Vosk (офлайн): разрешение + назначение системным
  /system/bin/pm grant io.github.mrpitonych.nogmsvoice android.permission.RECORD_AUDIO >/dev/null 2>&1
  /system/bin/settings put secure voice_recognition_service io.github.mrpitonych.nogmsvoice/.VoskRecognitionService >/dev/null 2>&1
  /system/bin/settings put global nogmsvoice_audio_source mic >/dev/null 2>&1
  echo "--- voice configured" >> $LOG
  echo "--- restore-apps done" >> $LOG
) &

exit 0
