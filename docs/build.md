# Как собирается образ

Краткое описание процесса. Точные команды конкретных сборок — в `scripts/`.

## Общая схема

```
stock 1.18.55 .bin
      ↓ распаковка (pack.py в обратную сторону)
   system.img (ext4)
      ↓ правки через debugfs
   sys_cNN.img  (≤ 371 077 блоков = 1 519 931 392 Б)
      ↓ упаковка (pack.py + configs/custom11855.ini)
   GIMI_XHAD01_XHC05_MAXIM_YN_WMP.bin
      ↓
   USB (FAT32) → проектор
```

## Структура `.bin` (MStar)

- Заголовок — текстовый скрипт для загрузчика: `mmc erase.p system` + несколько `mmc unlzo`.
- Тело — 10 частей, каждая в LZO.
- Хвост — footer 240 байт.

`set_config` и `recovery_wipe_partition data` **не используются**: первое ломает загрузку, второе
стирает данные пользователя.

## Правки в образе

Только `debugfs` (монтировать и `e2fsck` нельзя):

```bash
# добавить файл
debugfs -w -R "write local_file /path/inside/image" sys_cNN.img

# удалить файл
debugfs -w -R "rm /path/inside/image" sys_cNN.img

# выставить права и владельца
debugfs -w -R "sif /path mode 0100755" sys_cNN.img
debugfs -w -R "sif /path uid 0" sys_cNN.img
debugfs -w -R "sif /path gid 0" sys_cNN.img

# посмотреть
debugfs -R "ls -l /vendor/overlay" sys_cNN.img
```

Порядок: **сначала удаление**, потом добавление — иначе не хватит места.

## Упаковка

```bash
cd mbt
cp ../fw/work/sys_cNN.img pack/system.img
python pack.py configs/custom11855.ini
```

Результат: `GIMI_XHAD01_XHC05_MAXIM_YN_WMP.bin`.

## Проверка перед записью на флешку

```python
import re, os
head = open(BIN, "rb").read(6000).decode("latin-1")
parts = re.findall(r"filepartload 0x\w+ \S+ 0x([0-9A-F]+) 0x([0-9A-F]+)", head)
total = max(int(o,16)+int(s,16) for o, s in parts)
assert len(parts) == 10                    # 10 частей
assert os.path.getsize(BIN) - total == 240 # footer
assert "mmc erase.p system" in head
assert "set_config" not in head
```

Затем — SHA256 и сверка после копирования на флешку.

## Хук install-recovery.sh

Лежит в `/bin/install-recovery.sh`, права `0755`, **LF**. Выполняется при загрузке и делает:

1. `setprop service.adb.tcp.port 5555` + перезапуск `adbd`
2. запуск агента мониторинга
3. удаление 39 пакетов (`pm uninstall --user 0`)
4. установку 7 APK из `/system/etc/restore-apps/`
5. `pm disable-user com.sohu.inputmethod.sogou.tv`
6. настройку IME (LeanKeyboard), Aerial как Home, `stay_on=3`, отключение заставки

## Лимит и контроль места

`371 077` блоков — жёсткий предел. После каждой правки проверяйте:

```bash
stat -c %s sys_cNN.img   # ≤ 1519931392
```
