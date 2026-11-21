# Как сделаны переводы (RRO overlay)

## Почему не пересборка APK

Системные приложения подписаны ключом XGIMI и объявлены как `sharedUserId=android.uid.system`.
Пересборка ломает подпись: приложение либо не ставится, либо теряет доступ к системным API
(и, например, меню питания перестаёт работать). Root-доступа на устройстве нет, поэтому заменить
APK напрямую тоже нельзя.

**Решение — RRO (Runtime Resource Overlay):** отдельный APK в `/vendor/overlay/`, который
подменяет **только строковые ресурсы** целевого пакета. Система применяет его при загрузке, сам
пакет остаётся нетронутым и сохраняет подпись.

## Структура overlay-проекта

```
overlay_src/
├── AndroidManifest.xml
└── res/
    └── values-ru/
        └── strings.xml
```

`AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="ru.xgimi.setting.overlay">
    <overlay
        android:targetPackage="com.android.newsettings"
        android:priority="1"
        android:isStatic="true" />
    <application android:hasCode="false" />
</manifest>
```

`res/values-ru/strings.xml` — только те строки, которые нужно заменить:

```xml
<resources>
    <string name="settings_title">Настройки</string>
    <string name="power_off">Выключить</string>
</resources>
```

Ключевое: `targetPackage` должен **точно** совпадать с пакетом цели, имена строк — точно совпадать
с оригиналами (`aapt2 dump resources <apk>`).

## Сборка и подпись

```bash
aapt2 compile --dir overlay_src/res -o compile.zip
aapt2 link -o ru-setting-unsigned.apk \
    -I $SDK/platforms/android-34/android.jar \
    --manifest overlay_src/AndroidManifest.xml \
    compile.zip

# подпись любым валидным ключом (overlay не требует подписи XGIMI)
apksigner sign --ks ru_overlay.keystore --ks-pass pass:android ru-setting-unsigned.apk
```

## Установка в образ

```bash
debugfs -w -R "write ru-setting.apk /vendor/overlay/ru-setting.apk" sys_c34.img
```

## Результат по пакетам (C34)

| overlay | targetPackage | строк |
|---|---|---|
| `ru-setting.apk` | `com.android.newsettings` | 644 |
| `ru-sysui.apk` | `com.android.systemui` | 170 |
| `ru-gimiplayer.apk` | `com.xgimi.gimiplayer` | 263 |
| `ru-aerial.apk` | `app.orchard.tv` | 319 (не применяется — сторонний) |
| `ru-vcontrol.apk` | `com.xgimi.vcontrol` | 132 |
| `ru-smartcurtain.apk` | `com.xgimi.smartcurtain` | 62 |
| `ru-bootwizard.apk` | `com.xgimi.bootwizard` | 295 |
| `ru-xhplayer.apk` | `com.xgimi.xhplayer` | 64 |
| `ru-filemanager.apk` | `com.android.documentsui` | 347 |
| `ru-config.apk` | `com.xgimi.config` | 19 |
| `ru-soundermode.apk` | `com.xgimi.soundermode` | 3 |
| `ru-bluetooth.apk` | `com.android.bluetooth` | 57 |

## Подводные камни

- **Несколько `%s` без позиционных** → `aapt2` собирает APK пустым. Добавьте `formatted="false"`.
- **Overlay не работает для сторонних приложений** (Aerial) — для них нужен APK с `values-ru`.
- **Кириллица в `values-ru`** требует, чтобы в APK был шрифт с кириллицей; системный
  `NotoSansCJK` покрывает её.
- **Проверяйте результат** после прошивки: `pm list packages | grep ru.xgimi` — должны быть
  установлены overlay-пакеты.
