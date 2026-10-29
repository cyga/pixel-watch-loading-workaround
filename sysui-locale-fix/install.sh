#!/bin/bash
IP="$1"
PORT="$2"
set -eux
adb -s $IP:$PORT install -r sysui-locale-fix.apk
adb -s $IP:$PORT shell pm grant dev.sasha.sysuilocale android.permission.CHANGE_CONFIGURATION
