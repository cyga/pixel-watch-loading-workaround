#!/usr/bin/env bash
# Pixel Watch: обход бага "Loading..." во время тренировки при русском языке.
# Переключает только Wear SystemUI на en-US. Нужно запускать после КАЖДОЙ перезагрузки часов.
# Перед запуском: на часах включить "Отладка по Wi-Fi" (пара с этим ноутбуком уже создана).
# Откат: ./fix-watch-loading.sh --undo
set -euo pipefail
PKG=com.google.android.wearable.sysui

if [ -n "${1:-}" ] && [ "$1" != "--undo" ]; then ADDR="$1"; else
  echo "detect address"
  ADDR=$(timeout 6 avahi-browse -rtp _adb-tls-connect._tcp 2>/dev/null |
    awk -F';' '/^=.*IPv4/{print $8":"$9; exit}') || true
fi
if [ -z "${ADDR:-}" ]; then
  echo "Часы не найдены в сети. Включите отладку по Wi-Fi или укажите адрес: $0 IP:PORT" >&2
  exit 1
fi
echo "connecting..."
adb connect "$ADDR" >/dev/null
echo "wait for device"
adb -s "$ADDR" wait-for-device

echo "reset locale"
adb -s "$ADDR" shell cmd locale set-app-locales $PKG --user 0 --locales '""'
if [ "${1:-}" = "--undo" ] || [ "${2:-}" = "--undo" ]; then
  echo "Переопределение снято."
  exit 0
fi
sleep 2
echo "set locale to en-US"
adb -s "$ADDR" shell cmd locale set-app-locales $PKG --user 0 --locales en-US
sleep 3
CFG=$(adb -s "$ADDR" shell dumpsys activity processes $PKG | grep -m1 'Configuration=' | grep -o '\[[^]]*\]' | head -1)
echo "Локаль процесса SystemUI: $CFG"
case "$CFG" in *en_US*) echo "OK — можно запускать тренировку." ;; *)
  echo "НЕ применилось." >&2
  exit 2
  ;;
esac
