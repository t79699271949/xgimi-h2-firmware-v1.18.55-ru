# XGIMI H2 — Russian firmware 1.18.55 (build C34)

Unofficial, community-made **Russian-localized firmware for the XGIMI H2 projector** (MStar SoC,
Android 6.0 / API 23, build `aosp_synsepalum_YN-userdebug`).

Based on the stock **1.18.55** firmware. Everything works offline, out of the box, and survives a
factory reset — the Russian UI and the restoration of apps are baked into the system image, not
installed by hand.

> ⚠️ **Flash at your own risk.** This is not an official XGIMI release. See [DISCLAIMER.md](DISCLAIMER.md).

---

## 📥 Download

**[Download the firmware image (≈ 1 GB)](https://github.com/t79699271949/xgimi-h2-firmware-v1.18.55-ru/releases/download/v1.18.55-c34/GIMI_XHAD01_XHC05_MAXIM_YN_WMP.bin)**

- All releases: [Releases](https://github.com/t79699271949/xgimi-h2-firmware-v1.18.55-ru/releases)
- The file is `GIMI_XHAD01_XHC05_MAXIM_YN_WMP.bin` — no other `.bin` may be on the USB drive
- SHA256 for verification: `69fffe49fbf7dc858badac32cf0999f943e2e355a5a384cd8b70e749e911601b` (see [checksums.txt](checksums.txt))

Step-by-step flashing guide: **[FLASHING.md](FLASHING.md)**.

---

## ⚠️ Compatibility — read before downloading

**For XGIMI H2 only**, platform `synsepalum_YN` (the device reports itself as "XGIMI TV", MStar SoC,
Android 6.0). The hardware model in the official firmware filename is `XHAD01`.

### The Chinese and the global H2 are different systems

This build is based on the official **1.18.55 Chinese-branch** firmware: no Google services, but with
Chinese XGIMI components and `kuyun`. The global H2 runs a **different system**, and the two are
**not interchangeable** — XGIMI states they are "completely different systems" and cross-region
flashing causes "booting issues, system crash".

| Variant | Compatible |
|---|---|
| XGIMI H2 (Chinese version, MStar, Android 6) | ✅ yes |
| XGIMI H2 global (different system) | ❌ do not flash |
| XGIMI H1 / H1s | ❌ do not flash |
| XGIMI H2 Slim | ❌ do not flash |
| XGIMI H3, Horizon, MoGo, Elfin, Halo, Aura | ❌ do not flash |

### How to check your model

1. **Settings → About projector** — model and firmware version
2. The filename of the official firmware you downloaded from XGIMI for your device
3. Visually: the H2 has a Harman/Kardon speaker bar and 1080p output; the H2 Slim is the compact one

**If in doubt — don't flash.** An image for the wrong region or model can brick the projector with no
way back.

---

## What you get

| Area | Result |
|---|---|
| **System UI** | Chinese menus replaced with Russian (settings, power menu, curtain, errors, boot wizard) |
| **Power off / reboot** | Animations say «Выключение…» / «Перезагрузка…» instead of `正在关机中...` / `正在重启中...` |
| **Launcher** | Aerial 2.15 (Russian, tvOS-style) instead of the Chinese XGIMI launcher |
| **Local player** | Russian, plays video from USB drives |
| **HDMI player** | Russian |
| **File manager** | Russian (built in — survives factory reset) |
| **Keyboard** | LeanKeyboard (Russian), Chinese Sogou disabled |
| **Preinstalled apps** | Zona, SmartTube, TermOne (terminal), all restored automatically after a reset |
| **Junk removed** | 39 packages: ads, telemetry, Chinese app market, CIBN/streaming players, screensavers, skins, screen casting |
| **Monitoring agent** | Small HTTP agent on port 8081: CPU temperature, frequency, history (optional) |
| **ADB** | Enabled on boot, port 5555 |
| **Offline speech recognition** | Vosk `small-ru` service installed and preconfigured (needs an external USB microphone — the projector has no built-in mic wired in the audio policy) |

## Requirements

- XGIMI H2 projector (MStar). **Not** for other models.
- **USB flash drive, FAT32**, at least 2 GB free.
- The archive must contain exactly **one** `.bin` file in the root of the drive.
- Understand that a failed flash may brick the device.

## How to flash

See **[FLASHING.md](FLASHING.md)** — a step-by-step guide with no jargon.

Short version: copy the `.bin` to a FAT32 USB drive → insert into the projector → hold the power
button on the body → run the update → **remove the drive when it reboots**.

## Rolling back

The stock 1.18.55 image is the rollback path. Keep your own copy of the original firmware before
flashing — see [DISCLAIMER.md](DISCLAIMER.md).

## For AI agents / automation

If you are an AI assistant working on this repository, read **[AGENTS.md](AGENTS.md)** first. It lists
the hard rules of this image (what must never be touched, image size limits, known pitfalls).

## Technical documentation

- [docs/build.md](docs/build.md) — how the image is assembled (debugfs, packing, size limits)
- [docs/overlay.md](docs/overlay.md) — how the translations are applied without touching APKs (RRO)
- [docs/pitfalls.md](docs/pitfalls.md) — mistakes that cost hours; read before changing anything
- [CHANGELOG.md](CHANGELOG.md) — build history C1 → C34

## Credits & legal

Firmware components belong to XGIMI, MStar and the Android Open Source Project. This project only
redistributes a modified system partition for owners of the device. See [DISCLAIMER.md](DISCLAIMER.md).

Русское описание — [README.ru.md](README.ru.md).
