#!/usr/bin/env bash
# Ставит sysui-locale-fix.apk на часы и выдаёт разрешение CHANGE_CONFIGURATION.
# Использование: ./install.sh IP:PORT   (или ./install.sh IP PORT)
set -euo pipefail
cd "$(dirname "$0")"

if [ $# -eq 2 ]; then ADDR="$1:$2"; elif [ $# -eq 1 ]; then ADDR="$1"; else
  echo "Использование: $0 IP:PORT" >&2; exit 1
fi
[ -f sysui-locale-fix.apk ] || ./build.sh

adb connect "$ADDR" >/dev/null || true
adb -s "$ADDR" install -r sysui-locale-fix.apk
adb -s "$ADDR" shell pm grant dev.sasha.sysuilocale android.permission.CHANGE_CONFIGURATION
echo "Готово. Откройте «SysUI EN» на часах хотя бы один раз, чтобы заработал автозапуск после загрузки."
