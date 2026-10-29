#!/usr/bin/env bash
# Pixel Watch: обход бага «Loading…» во время тренировки при русском языке.
# Переключает на en-US только Wear SystemUI, язык часов остаётся русским.
# Запускать после КАЖДОЙ перезагрузки часов (или поставить приложение sysui-locale-fix).
#
# Перед запуском: на часах включена «Отладка по Wi-Fi», пара с этим компьютером создана (adb pair).
#
# Использование:
#   ./fix-watch-loading.sh              найти часы в сети и применить
#   ./fix-watch-loading.sh IP:PORT      применить к часам по адресу
#   ./fix-watch-loading.sh [IP:PORT] --undo   снять переопределение
set -euo pipefail
PKG=com.google.android.wearable.sysui

ADDR=""
UNDO=0
for arg in "$@"; do
  case "$arg" in
    --undo) UNDO=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) ADDR="$arg" ;;
  esac
done

if [ -z "$ADDR" ]; then
  echo "Ищу часы в сети…"
  for _ in 1 2 3; do
    ADDR=$(timeout 6 avahi-browse -rtp _adb-tls-connect._tcp 2>/dev/null |
      awk -F';' '/^=.*IPv4/{print $8":"$9; exit}') || true
    [ -n "$ADDR" ] && break
  done
fi
if [ -z "$ADDR" ]; then
  echo "Часы не найдены. Включите отладку по Wi-Fi или укажите адрес: $0 IP:PORT" >&2
  exit 1
fi

echo "Подключаюсь к $ADDR…"
OUT=$(adb connect "$ADDR" 2>&1 || true)
case "$OUT" in
  connected*|"already connected"*) ;;
  *) echo "Не удалось подключиться к $ADDR: $OUT" >&2
     echo "Нет пары с этими часами? Сделайте: adb pair IP:PORT КОД" >&2
     exit 1 ;;
esac
timeout 15 adb -s "$ADDR" wait-for-device || { echo "Часы не ответили за 15 с" >&2; exit 1; }

echo "Сбрасываю локаль SystemUI…"
adb -s "$ADDR" shell cmd locale set-app-locales "$PKG" --user 0 --locales '""'
if [ "$UNDO" = 1 ]; then
  echo "Переопределение снято."
  exit 0
fi
sleep 2

echo "Ставлю en-US…"
adb -s "$ADDR" shell cmd locale set-app-locales "$PKG" --user 0 --locales en-US
sleep 3

CFG=$(adb -s "$ADDR" shell dumpsys activity processes "$PKG" | grep -m1 -o 'Configuration={[^]]*]' | grep -o '\[.*\]')
echo "Локаль процесса SystemUI: $CFG"
case "$CFG" in
  *en_US*) echo "OK — можно запускать тренировку." ;;
  *) echo "Не применилось." >&2; exit 2 ;;
esac
